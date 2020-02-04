

#Peaks of People - The Prominence Calculator

###Overview

This interactive tool built using R Shiny introduces a different way of conceptualizing population density and the ranking of population centers.  This idea borrows a statistical method from physical geography—topographical prominence—to suggest a new technique for measuring the relative significance or rank of population centers. Unlike raw population measures, prominence gives consideration to both the spatial intensity of concentrated population areas as well as the spatial dependence or independence of neighboring settlement clusters in relation to one another. Here you are able to use the calculator to compare counting-based ranking with prominence-based ranking using a global 1 km resolution gridded population data set (from the European Commission - Global Human Settlement Layer: https://ghsl.jrc.ec.europa.eu/).

If you want to dig deeper in to the theory behind this approach, please ***read the paper:***

[Peaks of People: Using Topographic Prominence as a Method for Determining the Ranked Significance of Populaiton Centers](https://www.tandfonline.com/doi/full/10.1080/00330124.2018.1531039)

By Garrett Dash Nelson and Ryan McKeon, The Professional Geographer, 2019, v71.2 

###Getting the Prominence Calculator

**Online via shinyapps.io:** https://ryanmckeon.shinyapps.io/promAppV4/   -or-

**Locally via RStudio:** Download the global.R, server.R, and ui.R files that run this Shiny App and also download the GHS 1 km population grid from https://ghsl.jrc.ec.europa.eu/ ***note:*** *you will need to reproject this data set into ESPG: 4326 (WGS 1984) for it to work with the RLeaflet maps it generates.* 

####How to Use the Calculator

1. Choose the type and name of analysis region (US State or Country).

2. Decide if you want to buffer the border of your analysis region (i.e. consider neighboring populations).

3. Set the size of the analysis box and minimum threshold that defines a peak of population. 

4. Hit "Run It" at the bottom and watch a map pop up identifying the population centers that rise above your threshold. Note that the Map is dynamic, you can pan, zoom, and click on the peaks to find the population.

5. You can try multiple runs with different peak thresholds, for computation time reasons, it is best to have a maximum of ~15 peaks.

6. When you are happy with the minimum peak height, click on "Peaks with Prominence" to calculate the prominence of the peaks you identified.