library(shiny)
library(shinyalert)
library(shinyWidgets)


ui <- fluidPage(
  # Application title
  titlePanel("Population Prominence Calculator"),

  # Sidebar Where Calculation Parameters Are Set By User
  sidebarLayout(
    sidebarPanel(
      
      # add radio buttons
      radioButtons("location", "Analyze a...", 
                   c("US State" = "state",
                     "Country" = "country")),
      
      selectInput("placeNameState", "Pick a State", stateList),
      selectInput("placeNameWorld", "Pick a Country", worldList),
      
      radioButtons("buffer_ON", "Buffer the Location Borders?", 
                   c("Yes" = "yes",
                     "No" = "no")),
      
      # Set Summing Window Size
      sliderInput("sumWidth",
                  "Square Smoothing Window Size (km):",
                  min = 3,
                  max = 21,
                  value = 11,
                  step = 2),
      

      
      # Set Minimum Peak Height Value
      shinyWidgets::sliderTextInput("minPeakHeight","Minimum Peak Height (population):",
                                    choices=numRange,
                                    selected=1000, grid = F),
      
      # Set Prominence Tolerance
      sliderInput("promTolerance",
                  "Prominence Calculation Precision:",
                  min = 0,
                  max = 2500,
                  value = 1000,
                  step = 25), 
      
      
      radioButtons("calc_prom", "What to Calculate?", 
                   c("Peaks Only" = "peaks",
                     "Peaks with Prominence" = "prominence")),
      
      
      useShinyalert(),  # set up error window if no peaks are found
      # Find Peaks Button
      actionButton("go", "Run It")
      #downloadButton("downloadData", "Download CSV Table")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      fluidRow(
        h3("Read the paper"),
        h4(a("Peaks of People: Using Topographic Prominence as a Method for Determining the Ranked Significance of Populaiton Centers", href="https://www.tandfonline.com/doi/full/10.1080/00330124.2018.1531039")),
        strong(em("By Garrett Dash Nelson and Ryan McKeon, The Professional Geographer, 2019, v71.2")),
        br(),
        h3("Using Prominence as a Metric"),
        p("This idea borrows a statistical method from physical geography—topographical prominence—to suggest a new technique for measuring the relative significance or rank of population centers. Unlike raw population measures, prominence gives consideration to both the spatial intensity of concentrated population areas as well as the spatial dependence or independence of neighboring settlement clusters in relation to one another. Here you are able to use the calculator to compare counting-based ranking with prominence-based ranking using a global 1 km resolution gridded population data set."),
        h3("How to Use the Calculator"),
        p("1.  Choose the type and name of analysis region (US State or Country)."),
        p("2.  Decide if you want to buffer the border of your analysis region (i.e. consider neighboring populations)."),
        p("3.  Set the size of the analysis box and minimum threshold that defines a peak of population. "),
        p('4.  Hit "Run It" at the bottom and watch a map pop up identifying the population centers that rise above your threshold. Note that the Map is dynamic, you can pan, zoom, and click on the peaks to find the population.'),
        p("5.  You can try multiple runs with different peak thresholds, for computation time reasons, it is best to have a maximum of ~15 peaks."),
        p('6.  When you are happy with the minimum peak height, click on "Peaks with Prominence" to calculate the prominence of the peaks you identified.'),
        br(),
        h3("Prominence Calculator Results"),
        p("The map below is dynamic, you can pan, zoom, and click on the points for information.")
        ),
      
      
      
      
      leafletOutput("Lmap", height = 600)
      #plotOutput("plot")
      #dataTableOutput("peaksData")
    )
  )
)
