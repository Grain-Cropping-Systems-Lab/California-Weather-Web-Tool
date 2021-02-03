library(shinydashboard)
conflictRules("plotly", exclude = c("add_markers", "add_polygons"))
library(plotly)
library(googleway) # package for Google Map capabilities
library(tidyr)
library(dplyr)
library(shinyBS)
library(shinycssloaders)
library(ggplot2)
library(shinyWidgets)
library(shinyjs)
library(plotly)

# define the header for the web-tool
source("../modules/dashboard_header_weather.R")

# the map module uses a Google API key in order to be fully functional
source("../modules/map_module.R")
api_key <- Sys.getenv("MAPS_API_KEY")

# load the functions that gather the prism data over a date range
source("../functions/prism_date_range_all.R")
source("../functions/prism_historical_season_all_steps.R")

# load the functions to create the total water and temperature plots
source("../functions/total_water_plot_fn.R")
source("../functions/temp_plot_fn.R")

# load the function that defines how different regions of the shapefile behave
# The shapefile we have loaded and defined allows users to select a point of interest within California.
source("../functions/region_behavior_weather_fn.R")

# information specific to host's database
# the 'con' variable is used throughout to make calls to the database that stores all the weather data
# we use a spatially explicit table in a PostGres database for speed and ease of use with this large amount of data
readRenviron("../.Renviron")
con <- "ENTER DATABASE CONNECTION HERE"

# define global max dates for the forecast and PRISM data
max_forecast_date <- DBI::dbGetQuery(con, "SELECT DISTINCT(date) FROM grain.prism WHERE quality = 'forecast' ORDER BY date DESC LIMIT 1;")
max_prism_date <- DBI::dbGetQuery(con, "SELECT DISTINCT(date) FROM grain.prism WHERE quality != 'forecast' ORDER BY date DESC LIMIT 1;")