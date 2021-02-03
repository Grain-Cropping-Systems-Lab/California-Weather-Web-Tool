server <- function(input, output, session) {

	runjs(slider_js)
	dashboard_header_server("header")

	map_outputs <- map_mod_server("map_mod",
								 shapefile_path = "../files/ca_outline.shp",
								 region_behavior = region_behavior_weather,
								 default_lat = 38.533867,
								 default_lon = -121.771598)


	observeEvent(input$switchtab, {
		print("next clicked")

		irrigation <- data.frame(date = as.Date(character()), amount = numeric())
		
		check_dates_fn <- function(daterange){
			
			if (is.na(daterange[1]) | is.na(daterange[2])){
				showNotification("Error: the date range is not complete.")
				return(FALSE)
			} 
			
			if (daterange[1] > daterange[2]){
				showNotification("Error: the entered start date occurs after the end date.")
				return(FALSE)
			}
			
			if (daterange[2] - daterange[1] > 365) {
				showNotification("Error: the entered date range is longer than one year!")
				return(FALSE)
			}
			
			if(as.Date(paste0(lubridate::year(daterange[1]), "-10-01")) <= daterange[1]){
				end_date <- as.Date(paste0(lubridate::year(daterange[1]) + 1, "-10-01"))
				print(end_date)
			} else {
				end_date <- as.Date(paste0(lubridate::year(daterange[1]), "-10-01"))
				print(end_date)
			}
															
			if(daterange[2] > end_date){
				showNotification("Error: the entered date range is outside of the water year!")
				return(FALSE)
			}
			
			return(TRUE)
	}
			
		check_dates <- check_dates_fn(input$daterange)
		
			if(check_dates == TRUE){
				
				updateButton(session, inputId = "switchtab", label = "Next", block = TRUE, style="default", size = "lg", disabled = TRUE)
				updateTabItems(session, "tabs", "initial_outputs")
				
				
				withProgress(message = "Gathering current and historical season data...", value = 0, min = 0, max = 100, {
					historical_data <- prism_historical_season_all(con = con,
																												 lat = map_outputs$lat,
																												 long = map_outputs$lon,
																												 current_start_date = input$daterange[1],
																												 end_date = input$daterange[2]
					)
					
					
					incProgress(10)
					
					present_data <- prism_date_range_all(con = con, lat = map_outputs$lat, long = map_outputs$lon, from_date = input$daterange[1], to_date = input$daterange[2])
					
				}) # end of progress bar tracking
				
				historical_data_long <- historical_data %>%
					mutate(time = "historical",
								 quality = "historical",
								 date = pseudo_date) %>%
					select(-pseudo_date) %>%
					gather(measurement, amount, -date, -month, -day, -time, -quality)
				
				present_data_long <- present_data %>%
					mutate(time = "present",
								 quality = if_else(quality == "forecast", "forecast", "prism")) %>%
					gather(measurement, amount, -date, -month, -day, -time, -quality)
				
				weather_data <- bind_rows(present_data_long, historical_data_long) %>% 
					drop_na(amount)
				
				print("calculating total water data without irrigation")
				total_water <- weather_data  %>%
					filter(measurement == "ppt",
								 date <= max(present_data$date)) %>%
					mutate(amount = amount/25.4) %>%
					group_by(time) %>%
					arrange(date) %>%
					mutate(water_cumsum = cumsum(amount))
				
				
				output$rainfall <- renderValueBox({
					
					# total water value to be used in value box (excludes any forecast data)
					tw <- total_water %>%
						filter(time == "present",
									 quality != "forecast") %>%
						ungroup() %>%
						select(water_cumsum) %>%
						max() %>%
						as.numeric() %>%
						round(1)
					
					# historical water value to be used in value box
					max_date <- total_water %>%
						filter(time == "present", quality != "forecast") %>%
						ungroup() %>%
						select(date)
					
					max_date <- max(max_date$date)
					
					hw <- total_water %>%
						filter(time == "historical") %>%
						ungroup() %>%
						filter(date == max_date) %>%
						select(water_cumsum) %>%
						as.numeric() %>%
						round(1)
					
					valueBox(value = tags$p(paste(tw, " in (", ifelse(tw-hw >= 0, "+", ""),
																				round(tw-hw, 1), " in of average)", sep = ""), style = "font-size: 50%"),
									 subtitle = "Cumulative precipitation", color = "blue"
					)
				})
				
				tw_ranges <- reactiveValues(x = NULL, y = c(0, max(total_water$water_cumsum) + max(total_water$water_cumsum)*.1))
				output$total_water_plotly <- renderPlotly(total_water_plot(weather_data = weather_data, 
																																	 total_water = weather_data,
																																	 irrigation = irrigation,
																																	 present_data = present_data,
																																	 lat = map_outputs$lat,
																																	 long = map_outputs$lon,
																																	 ranges = tw_ranges))
				
				output$temp_plot <- renderPlotly(temp_plot_fn(weather_data = weather_data, lat = map_outputs$lat,
																											long = map_outputs$lon))
				
				
				output$downloadCSV <- downloadHandler(
					
					filename = function() {
						paste0("weather_data_", "lat_", map_outputs$lat, "_long_", map_outputs$lon, "_", input$daterange[1], "_", input$daterange[2], ".csv")
					},
					content = function(file) { write.csv(x = weather_data %>%
																							 	filter(measurement == 'ppt' | measurement == 'tmax' | measurement == 'tmin') %>%
																							 	mutate(key = if_else(measurement == "ppt", paste(measurement, time, "in", sep = "_"),
																							 											 paste(measurement, time, "F", sep = "_")),
																							 				 data_type = if_else(quality == "prism", "current", quality),
																							 				 amount = if_else(measurement == "ppt", amount/25.4, amount)) %>%
																							 	select(-measurement, - time, -quality, -data_type) %>%
																							 	spread(key = key, value = amount),
																							 file, row.names = FALSE) }
				)
				
			}


	})

	observeEvent(input$back, {
		print("back clicked")
		updateTabItems(session, "tabs", "location")
		updateButton(session, inputId = "switchtab", label = "Next", block = TRUE, style="default", size = "lg", disabled = FALSE)
	})


}
