# Load Libraries
library(raster)
library(sf)
library(sp) 
library(leaflet)
library(shiny)
library(spData)
library(rgdal)
library(igraph)
library(shinyalert)
library(emdbook)


server <- function(input, output) {
  
  PromCalculator <- eventReactive(input$go, {
    
    # **********************************************************************
    # Choose State or Country to calculate promenince for and clip down the GHS population data set accordingly
    # **********************************************************************
    
    if (input$location == "state") {
      # Get the USA Shapefile
      USA_shp <- us_states
      # subset the US shapefile down to a single state
      state_shp = USA_shp[USA_shp$NAME == input$placeNameState, ]
      
      # Buffering the border? 
      
      # yes... set the buffer to 0.25 DD or ~25 km
      if (input$buffer_ON == "yes") {
        stateBUFF = st_buffer(state_shp, 0.25)
        # buffer it!
        clipArea = stateBUFF
      }
      # no...  but let's buffer a little to make up for the weird raster edge effects
      else if (input$buffer_ON == "no") {
        # assign clipping mask to country outline
        stateBUFF = st_buffer(state_shp, 0.02)
        # buffer it!
        clipArea = stateBUFF
      }
      
    } else if (input$location == "country") {
      # Get the World Shapefile
      WORLD_shp <- world
      WORLD_shp$NAME <- WORLD_shp$name_long
      # subset the World shapefile down to a single country
      country_shp = WORLD_shp[WORLD_shp$NAME == input$placeNameWorld, ]
      
      # Buffering the border? 
      
      # yes... set the buffer to 0.25 DD or ~25 km
      if (input$buffer_ON == "yes") {
        countryBUFF = st_buffer(country_shp, 0.25)
        # buffer it!
        clipArea = countryBUFF
      }
      # no...  but let's buffer a little to make up for the weird raster edge effects
      else if (input$buffer_ON == "no") {
        # assign clipping mask to country outline
        countryBUFF = st_buffer(country_shp, 0.03)
        # buffer it!
        clipArea = countryBUFF
      }
    }
    
    # clip the World 1 km population dataset with the selected state or country
    cropRaster = crop(inRaster,clipArea)
    
    # this makes the promRaster and is the output for the function
    promRaster = mask(cropRaster,clipArea)            
    #plot(promRaster)  # plot the clipped down input population raster
    #plot(promRaster)
    
    
    # ********************************************************************************
    #                            FIND PEAKS
    # ********************************************************************************
    
    # Focal Functions
    # Summed Population Grid -- Smoothing
    sumGrid = focal(promRaster, w=matrix(1,input$sumWidth,input$sumWidth), fun=sum, na.rm=TRUE)  # this is a user defined square window for the summing focal function
    analysis_area = input$sumWidth * input$sumWidth  # compute moving window area for legend below
    
    #plot(sumGrid, main = "Summed Population Grid")
    
    # Maximum Population Gird
    maxGrid = focal(sumGrid, w=matrix(1,input$sumWidth,input$sumWidth), fun=max)  # this is a user defined square window to find the max value in the window
    #plot(maxGrid, main='Maximum Value')
    
    # Find the Peaks -- where sumGrid equals maxGrid
    diffGrid = maxGrid - sumGrid
    #plot(diffGrid, main='sumGrid - maxGrid')
    # keep only cells of zero value (meaning Max = Sum value)
    peaksGridRaw = diffGrid
    peaksGridRaw[peaksGridRaw > 0] = NA  # keep only those cells that equal zero
    peakHeight = peaksGridRaw + 1        # give peaks a value of 1 not zero
    peaksGrid = peakHeight * sumGrid     # multiply by sumGrid to get the hieght of the peak
    
    #plot(peaksGrid, main='peaksGrid')
    summary(peaksGrid)
    
    # Convert raster of peak pixels to points and apply minimum height threshold
    peakPTs = rasterToPoints(peaksGrid, fun=function(x){x>input$minPeakHeight})
    
    # Trap out situation where no peaks rose above the threshold
    if (length(peakPTs) == 0) {
      shinyalert("Oops! No Peaks Found, lower your minmum peak height or increase your analysis square size", type = "error")
    }
    
    # convert to dataframe
    peaksDF = data.frame(peakPTs)
    
    # make the peaks an sf spatial object with the WGS84 projection
    # UTM zone 19n -> wgs84 EPSG:32619
    # NAD83/Conus Albers = EPSG: 5070
    # WGS84 = EPSG: 4326
    peakPTs_shp <- st_as_sf(peaksDF, coords = c("x", "y"), crs = 4326)
    # Add a field to peaksPTs_shp and change the name of the "layer" field to "sumPop""
    peakPTs_shp$sumPop = peakPTs_shp$layer  # add the new field and put the data in it
    
    
    #shapefile_exists = "FALSE"
    
    
    # Check Radio Button to see if this is the end (i.e. Only Finding Peaks)
    
    if (input$calc_prom == "peaks")  {
      # Plot the Summed Population Grid and the identified peaks on top.
      #plot(sumGrid, main = "Summed Population with Peaks above Threshold", reset = FALSE)
      #plot(peakPTs_shp["sumPop"], pch=19, add = TRUE)
      peakPTs_shp$popRank = rank(-peakPTs_shp$sumPop)  # Add a population rank column and order it in descending values (i.e. rank 1 is the highest population)
      
      # Finished if not calculating prominence
      
      # Make a Map with Peak information
      grid_pal <- colorNumeric(c("#e8e7e6", "#41B6C4", "#0C2C84"), values(sumGrid), na.color = "transparent")
      legend_title = paste("Total Population in<br>", toString(input$sumWidth), "km Analysis Box")
      
      
      Lmap <- leaflet(peakPTs_shp, height = 800) %>%  # create the map and give it the peakPTs_shp data
        addProviderTiles(providers$CartoDB.Positron) %>%  # add CardoDB Map Tiles
        addRasterImage(sumGrid, colors = grid_pal, opacity = 0.6) %>%
        addLegend(pal = grid_pal, values = values(sumGrid), title = legend_title) %>%
        addCircleMarkers(radius=5, fill = TRUE, stroke = TRUE, color = "black", weight = 1,  fillColor = "black", fillOpacity = 0.6, popup = ~paste("<b>Population Rank: </b>", popRank, "<br><b>Population: </b>", round(sumPop), "<br>"))  # build circle markers showing the peakPTs_shp data with popups
      Lmap
    }
    
    else if (input$calc_prom == "prominence")  {
      
      # Time to caclculate the prominence!
      
      # ********************************************************************************
      #                   CALCULATE PROMINENCE FOR EACH PEAK
      # ********************************************************************************
      
      ## Now comes the fun... loop through the peaks and search for peaks of greater value contained by a population contour.
      
      
      #peakPTs_shp$layer=NULL    # drop the 'layer' field from the dataframe
      peakPTs_shp$Prom = 0    # add a field for prominence and populate it with zeros
      howMany = nrow(peakPTs_shp)
      #maxPeakHeight = as.integer(max(peakPTs_shp$sumPop))  # find the maximum peak height for all peaks
      maxPeakHeight = as.integer(max(peakPTs_shp$sumPop)) 
      
      
      for (i in 1:howMany) {
        # get the height of the current peak
        currentPeak = peakPTs_shp[i, ]     # this is an sf object with geometry
        currentHeight = as.integer(currentPeak$sumPop)  # this is a variable with a single float value
        
        # screen to see if this is the highest peak
        if (maxPeakHeight == currentHeight) {
          # set prominence to currentHeight because nothing is taller in the study area
          peakPTs_shp[i,4] = currentHeight
          
          # This is not the highest peak in the land...  search for prominence
        } else {
          
          # Drain the Tub Loop *** BISECTION SEARCH *** --- Go to the middle and then work up or down
          firstContour = as.integer(currentHeight/2)  # start the search at the mid point
          rangeHigh = currentHeight
          rangeLow = 0
          withinThreshold = FALSE
          testPOP = 0
          contour = firstContour
          j = 0
          
          # Loop through Bisection Search to find Prominence
          while (withinThreshold == FALSE) {
            j = j+1
            # fill tub to current control height, keep only what stands above water level
            tubLevel = sumGrid > contour
            # clump the islands sticking above the tub level
            clumps = clump(tubLevel)
            # find the island the currentPeak is on
            currentPeakIsland = extract(clumps, currentPeak, method='simple')
            # find the max height on each island
            islandMax = zonal(sumGrid, clumps, fun='max')  
            
            # ++++++++++ All looks good to this point  +++++++++++++++++++++
            # the command below did not work
            
            islandMaxPeak = as.integer(islandMax[currentPeakIsland,2]) # find the height of the highest peak on the island
            
            # print some loop info to the console
            cat('Current Peak Height is ', currentHeight, '\n')
            cat('Island Max Peak is ', islandMaxPeak, '\n')
            
            # we have the info... lets see if we need to keep searching
            testValue = rangeHigh - rangeLow
            
            # We are DONE! 
            if (testValue <= input$promTolerance ) {   
              withinThreshold = TRUE
              prominence = currentHeight - contour  # calculate and store the prominence
              peakPTs_shp[i,4] = prominence
              cat('\n', 'FOUND IT! The prominence is: ', prominence, '\n')
              
              # we are still the highest peak on the island, drain the tub some more  
            } else if (currentHeight == islandMaxPeak) {  
              rangeHigh = contour  # reset the Upper bound we will consider
              contour = contour - ((rangeHigh - rangeLow)/2)
              cat('Going Down, contour set to ', contour, '\n')
              
              # there is a higher peak on the island... fill the tub and keep hunting  
            } else { 
              rangeLow = contour  # reset the lower bound we will consider
              contour = contour + ((rangeHigh - rangeLow)/2)
              cat('Going Up, contour set to ', contour, '\n')
            }
          }
        }
      }
      
      # Calculate the ratio between population and promincence for each peak
      peakPTs_shp$ratio = peakPTs_shp$Prom/peakPTs_shp$sumPop
      peakPTs_shp$popRank = rank(-peakPTs_shp$sumPop)  # Add a population rank column and order it in descending values (i.e. rank 1 is the highest population)
      peakPTs_shp$promRank = rank(-peakPTs_shp$Prom) # ditto
      
      
      
      # Plot Results with Leaflet
      
      # Create the map with Leaflet Library Commands
      
      legend_title = paste("Peak Prominence<br>and Total Population in<br>", toString(input$sumWidth), "km Analysis Box")
      
      # color ramp for sumGrid -- Also Applied to peak prominence!
      grid_pal <- colorNumeric(c("#e8e7e6", "#41B6C4", "#0C2C84"), values(sumGrid), na.color = "transparent")
      
      Lmap <- leaflet(peakPTs_shp, height = 800) %>%  # create the map and give it the peakPTs_shp data
        addProviderTiles(providers$CartoDB.Positron) %>%  # add CardoDB Map Tiles
        addRasterImage(sumGrid, colors = grid_pal, opacity = 0.6) %>%
        addLegend(pal = grid_pal, values = values(sumGrid), title = legend_title) %>%
        addCircleMarkers(radius=10, fill = TRUE, stroke = TRUE, color = "black", weight = 1, fillColor = ~grid_pal(Prom), fillOpacity = 0.8, popup = ~paste("<b>Population Rank: </b>", popRank, "<br><b>Prominence Rank: </b>", promRank, "<br><b>Population: </b>", round(sumPop), "<br><b>Prominence: </b>", round(Prom), "<br><b>Ratio: </b>", round(ratio,3)))  # build circle markers showing the peakPTs_shp data with popups
      Lmap
      
      #write.csv(peakPTs_shp, "prominence_data_table.csv", sep = ",")
    
    }
    # Make output for table
    #peaksData = st_geometry(peakPTs_shp) <- NULL
    #return(peaksData)
    return(Lmap)
    #return(peakPTs_shp)
    
  })

  # Render Outputs  ---------------------------
  output$Lmap <- renderLeaflet({
    #Lmap  
    PromCalculator()  # here the PromCalculator function is being called to provide the plots that it generates internally
  })
  
  #output$downloadData <- downloadHandler()
  
  
  #output$peaksData = renderDataTable({
  #  #PromCalculator()
  #  peaksData = st_geometry(peakPTs_shp) <- NULL
  #})
}

#shinyApp(ui, server)