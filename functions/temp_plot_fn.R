temp_plot_fn <- function(weather_data, lat, long){

	named_labels <- c(forecast.tmax = 'Max Forecast', forecast.tmin = 'Min Forecast', historical.tmax = "Max Historical", historical.tmin = "Min Historical", present.tmax = "Current Max", present.tmin = "Current Min")
	named_colors <- c(forecast.tmax = 'gold', forecast.tmin = 'gold', historical.tmax = "orangered", historical.tmin = "dodgerblue", present.tmax = "orangered", present.tmin = "dodgerblue")
	named_lines <- c(forecast.tmax = 'solid', forecast.tmin = 'solid', historical.tmax = "dash", historical.tmin = "dash", present.tmax = "solid", present.tmin = "solid")

	county <- DBI::dbGetQuery(con, paste0("SELECT namelsad FROM grain.ca_counties WHERE ST_Contains(geom, ST_GeomFromText('POINT(", long, " ", lat, ")',4326));"))$namelsad
	plot_title <- paste0(c(""),
		substr(as.character(min(weather_data[weather_data$time == "present", "date"])), 6,10), " to ",
		substr(as.character(max(weather_data[weather_data$time == "present", "date"])), 6,10), " (", county, "; ", as.character(round(lat, 2)), ", ", as.character(round(long, 2)), ")")

	data <- weather_data %>%
		filter(measurement == "tmax" |
					 	measurement == "tmin")

	data_real <- data %>% filter(quality != 'forecast') %>%
				mutate(plot_group = interaction(time, measurement))

	data_forecast <- data %>% filter(quality == "forecast") %>%
				mutate(plot_group = interaction(quality, measurement))

	# connect the forecast and present tmax lines
	if(data_forecast %>% filter(plot_group == 'forecast.tmax') %>% nrow() > 0) {
		data_forecast <- rbind(data_forecast,
							data_real %>%
							filter(measurement == 'tmax', time == 'present', quality != 'forecast') %>%
							arrange(date) %>%
							tail(1) %>%
							mutate(quality = 'forecast', plot_group = 'forecast.tmax')
						)

			data_forecast <- data_forecast %>% arrange(date)
		}

		# and do the same for the tmin lines
		if(data_forecast %>% filter(plot_group == 'forecast.tmin') %>% nrow() > 0) {
			data_forecast <- rbind(data_forecast,
								data_real %>%
								filter(measurement == 'tmin', time == 'present', quality != 'forecast') %>%
								arrange(date) %>%
								tail(1) %>%
								mutate(quality = 'forecast', plot_group = 'forecast.tmin')
							)

				data_forecast <- data_forecast %>% arrange(date)
			}

	data <- rbind(data_real, data_forecast) %>%
				mutate(label = named_labels[as.character(plot_group)])


	fig <- plot_ly(
			hoverinfo = 'text', type = 'scatter',
			colors = named_colors, linetypes = named_lines
		)

	fig <- fig %>%
			add_trace(data = data, x = ~date, y = ~amount, type = 'scatter', mode = "lines",
			color = ~plot_group, name = ~label, linetype = ~plot_group,
			text = ~paste(label, "<br>", "Date: ", date, "<br>", "°F: ", round(amount, 1)))

		tick_font = list(size = 14)
		title_font = list(size = 14)

		fig <- fig %>% layout(title = plot_title, font = list(size = 11),
													xaxis = list(title = F, tickfont = tick_font, titlefont = title_font),
													yaxis = list(title = "Temperature (F)", tickfont = tick_font, titlefont = title_font),
													showlegend = T, legend = list(orientation = 'h', y = -0.25))

		return(fig)
}
