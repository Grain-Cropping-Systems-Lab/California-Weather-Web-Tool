ui <- dashboardPage(
	dashboard_header_ui("header", "Header"),
	dashboardSidebar(disable = TRUE,
									 sidebarMenu(id = "tabs",
									 						menuItem("location", tabName = "location", icon = icon("dashboard")),
									 						menuItem("initial_outputs", tabName = "initial_outputs")
									 )
	),
	dashboardBody(
		useShinyjs(),
		extendShinyjs("www/app-shinyjs.js", functions = c("updateHistory")),
		tags$head(
			tags$link(rel = "stylesheet", type = "text/css", href = "css/styles.css"),
			tags$script(type="text/javascript", async = T, src=paste0("https://www.googletagmanager.com/gtag/js?id=", Sys.getenv("ANALYTICS_KEY"))),
			tags$script(
				paste0("
					 window.dataLayer = window.dataLayer || [];
						function gtag(){dataLayer.push(arguments);}
						gtag('js', new Date());
						gtag('config', '", Sys.getenv("ANALYTICS_KEY"), "');")
			),
			tags$style(type="text/css", "#inline label{ display: table-cell; text-align: center; vertical-align: middle; padding-right: 20px;}
                #inline .form-group { display: table-row;}")
		),
		tags$div(id = 'anchor'),
		tabItems(
			tabItem(tabName = "location",
							fluidRow(
								column(6,
											 box(title = p("Location"), solidHeader = TRUE, status = "primary", width = 12,
											 		p("Click or move the marker to the location of interest. Data is available for the state of California."),
											 		map_mod_ui("map_mod")
											 		)),
											 column(6,
											 box(title = p("Period of interest"), solidHeader = TRUE, status = "primary", width = 12,
											 		HTML("Choose dates below that span the period of interest. Data is available from Jan. 1, 2009 to present, including a 10-day forecast for the major agricultural regions of California. Date range cannot exceed 1 year and must begin & end within a single water year (the California water year begins on October 1st)."),
											 		bsModal("modal1", "What is a wheat growing season?", "actionlink", size = "large", imageOutput("growingSeasonImage"),
											 						HTML("Jackson, L. and Williams, J. Growth and Development of Small Grains. Publication 8165 in <a href = 'https://anrcatalog.ucanr.edu/pdf/8208.pdf' target='_blank'>UC Small Grain Production Manual</a>.")),
											 		dateRangeInput('daterange', label = "", format = 'mm/dd/yyyy',
											 									 start = if_else(as.Date(paste0(lubridate::year(Sys.Date()),
											 									 															 "-10-01")) <= Sys.Date(),
											 									 								as.Date(paste0(lubridate::year(Sys.Date()), "-10-01")),
											 									 								as.Date(paste0(lubridate::year(Sys.Date())-1, "-10-01"))),
											 									 end = max_forecast_date$date,
											 									 min = as.Date("2009-01-01"), max = max_forecast_date$date)),
											 		br(),
											 #box(width = 12,
											 		#p("If you are satisfied with the information you entered and are ready to gather your site-specific data, click 'Next' below."),
											 		bsButton("switchtab", label = "Next", block = TRUE, style="default", size = "lg")#)
											 
								)
							)
			),
			tabItem(tabName = "initial_outputs",
							fluidRow(
								column(6,
											 box(title = p("Precipitation"),
											 		solidHeader = TRUE,
											 		status = "primary",
											 		width = 12,
											 		fluidRow(
											 			column(12,
											 						 valueBoxOutput("rainfall", width = 12)
											 			)
											 		),
											 		fluidRow(
											 			column(12,
											 						 	plotlyOutput("total_water_plotly") %>% shinycssloaders::withSpinner(type = 6, color="#005fae")
											 						 
											 			)
											 		))),
											 column(6,
											 			 box(title = p("Temperature"),
											 			 		solidHeader = TRUE,
											 			 		status = "primary",
											 			 		width = 12,
											 			 		fluidRow(
											 			 			column(12,
											 			 						 plotlyOutput("temp_plot") %>% shinycssloaders::withSpinner(type = 6, color="#005fae")
											 			 						 
											 			 			))
											 			 ), 
											 			 bsButton("back", label = "Back", block = TRUE, style="default", size = "lg"))),
											 
											 		fluidRow(
											 			column(12, 
											 						 downloadButton("downloadCSV", "Download CSV")
											 			)
											 		)
								)
								))
			)
