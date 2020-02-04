
# Load Libraries
library(raster)
library(sf)
library(sp) 
library(leaflet)
library(shiny)
library(spData)
library(rgdal)
library(shinyalert)
library(emdbook)


# prep some things

# get the raster
inRaster = raster("GHS_1km_worldpop.tif")
#peakPTs_shp = st_read("peakPTs_shp_NH.shp")

# Get the USA Shapefile  from spData library
USA_shp <- us_states

# get the WORLD Shapefile from spData library
WORLD_shp <- world
WORLD_shp$NAME <- WORLD_shp$name_long

# create and sort state and country lists for dropdown menus
stateList = sort(USA_shp$NAME)
worldList = sort(WORLD_shp$NAME)

# create variables to hold UI set parameters
location = "text"
buffer_ON = "text"

# create log scale number range for peak threshold slider
numRange = round(lseq(100,5000000,300), digits = -2)

# #  Create dummy output to hold the place for output from the prominence calculator
# grid_pal <- colorNumeric(c("#e8e7e6", "#41B6C4", "#0C2C84"), values(sumGrid), na.color = "transparent")
# 
# Lmap <- leaflet(peakPTs_shp) %>%  # create the map and give it the peakPTs_shp data
#   addProviderTiles(providers$CartoDB.Positron) %>%  # add CardoDB Map Tiles
#   addRasterImage(sumGrid, colors = grid_pal, opacity = 0.6) %>%
#   addLegend(pal = grid_pal, values = values(sumGrid), title = "Prominence") %>%
#   addCircleMarkers(radius=10, fill = TRUE, stroke = TRUE, color = "black", weight = 1,  fillColor = ~grid_pal(Prom), fillOpacity = 0.8, popup = ~paste("<b>Population: </b>", sumPop, "<br><b>Prominence: </b>", Prom, "<br><b>Ratio: </b>", ratio))  # build circle markers showing the peakPTs_shp data with popups
# 
# peaksData = peakPTs_shp %>% st_set_geometry(NULL)


#peaksOUT = data.frame()


