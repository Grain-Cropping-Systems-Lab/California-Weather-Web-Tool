region_behavior_weather <- function(shapefile, region_data, current_markers, testing_markers){
	current_markers$lat <- testing_markers$lat
	current_markers$lon <- testing_markers$lon
	return(current_markers)
}
