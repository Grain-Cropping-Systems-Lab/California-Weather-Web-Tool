dashboard_header_ui <- function(id, label = "header") {
	ns <- NS(id)
	dashboardHeader(title = "The California Weather Web-Tool", titleWidth = 350,
									tags$li(actionLink(ns("open_info_modal"),
																		 label = "",
																		 icon = icon("info-circle")),
													class = "dropdown"))
}

dashboard_header_server <- function(id){
	moduleServer(
		id,
		function(input, output, session){
			observeEvent(input$open_info_modal, {
				showModal(
					modalDialog(title = "About the California Weather Web-Tool",
											HTML("The California Weather Web-Tool uses present and historical precipitation and temperature data from PRISM Climate Group."),
											HTML(paste0("PRISM Climate Group, Oregon State University, http://prism.oregonstate.edu, created ", format(max_prism_date$date, format = "%d %b %Y"), ".")),
											br(), br(),
											HTML("To cite this page, please use: Nelsen, T., Merz, J., Rosa, G., & Lundy, M. (2021, January 27). <i>The California Weather Web-Tool.</i> Retrieved from http://smallgrain-n-management.plantsciences.ucdavis.edu/weather/"),
											br(), br(),
											HTML("We would also like to thank CDFA-Fertilizer Research and Education Program, NRCS-Conservation Innovation Grant, California Wheat Commission, California Crop Improvement Association, and the UC Davis, Library for their support of this project."),
											br(), br(),
											HTML("For questions about this content, please contact Mark Lundy, Assistant UC Cooperative Extension Specialist in Grain Cropping Systems (<a href = 'melundy@ucdavis.edu' target='_blank'>melundy@ucdavis.edu</a>).")
					)
				)
			})
		}
	)
}