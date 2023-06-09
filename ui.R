#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# consts

tab.name.dashboard <- "dashboard"
tab.name.main.map <- "specificMap"
tab.name.map.general <- "generalMap"
tab.name.forecast <- "forecast"
tab.name.main.graph <- "graphMap"
tab.name.tornadoes <- "tornadoesTab"
tab.name.climate <- "climate"
tab.name.about <- "about"

# Header

dbHeader <- dashboardHeader(title = div(icon("cloud-sun-rain")," Weather Report"),
                            tags$li(a(href = 'https://www.put.poznan.pl/',
                                      img(src = '/logo/PP_logotyp_ANG_CMYK.svg',
                                          title = "Poznań University Of Technology", height = "30px"),
                                      style = "padding-top:10px; padding-bottom:10px;"),
                                    class = "dropdown")
                            )

# tabs sidebar

dbSidebar <- dashboardSidebar(sidebarMenu(
    #menuItem("Dashboard", tabName = tab.name.dashboard, icon = icon("dashboard")),
    menuItem("Forecast", tabName = tab.name.forecast, icon = icon("calendar-days")),
    #menuItem("General Map", tabName = tab.name.map.general, icon = icon("map")),
    menuItem("Tornadoes in US", tabName = tab.name.tornadoes, icon = icon("tornado")),
    #menuItem("Climate change", tabName = tab.name.climate, icon = icon("earth-europe")),
    menuItem("Datatable", tabName = tab.name.main.map, icon = icon("table")),
    #menuItem("...graph its data", tabName = tab.name.main.graph,icon = icon("chart-line")),
    menuItem("About", tabName= tab.name.about, icon = icon("circle-info"))
  )
)

# about tab

tab.about <- tabItem(
  tabName = tab.name.about,
  includeMarkdown("README.md")
)

# forecast tab

tab.forecast <- tabItem(tabName = tab.name.forecast,
                        sidebarLayout(
                          sidebarPanel(h2("Double click to select a place"),leafletOutput(forecastMapOutput)),
                          mainPanel(box(plotOutput("forecastPlot"),
                                        plotOutput("windPlot"),width="100vw",height="100vw"))
                        ))

# general tab

# update.general <- actionButton("updateGeneral",
#                                "Update")
# 
# tab.general <- tabItem(tabName = tab.name.map.general,
#                        leafletOutput(generalMapOutput),
#                        update.general)

# datatable tab

weather.Options <- checkboxGroupInput(weatherOptions,
                                      "Weather options: ",
                                      c("Temperature" = "temperature_2m",
                                        "Humidity" = "relativehumidity_2m",
                                        "Rain" = "rain",
                                        "Snowfall" = "snowfall",
                                        "Cloudcover" = "cloudcover",
                                        "Visibility" = "visibility",
                                        "Dewpoint" = "dewpoint_2m",
                                        "Surface Pressure" = "surface_pressure",
                                        "Wind speed" = "windspeed_10m"),
                                        selected = c("temperature_2m")
)


tab.specific <- tabItem(tabName = tab.name.main.map,
                        sidebarLayout(
                          sidebarPanel(weather.Options,h2("Double click to select a place"),leafletOutput(specificMapOutput)),
                          mainPanel(box(h2("Select columns to graph them"),DTOutput(underMapDtOutput),width="100vw"))),
                        actionButton(graphColumnsButton,"Graph Data"),
                        box(plotOutput(graphColumns,height = 250,width="100vw"),width="100vw")
)

# tornado tab

select.Tornadoes <- checkboxGroupInput("selectTornadoes",
                                "F/EF scale: ",
                                c("EF0" = 0,"EF1" = 1,"EF2" = 2,"EF3" = 3,"EF4" = 4,"EF5" = 5),
                                selected = 2
)
update.Tornadoes <- actionButton("updateTornadoes",
                                 "Update")
clear.Tornadoes <- actionButton("clearTornadoes",
                                "Clear")
plotDetails.Tornadoes <- actionButton("plotTornadoes",
                                 "Update")

date.min <- min(dataset.tornadoes$date)
date.max <- max(dataset.tornadoes$date)
dateRange.Tornadoes <- dateRangeInput("dateRangeTornadoes",
                                      "Pick dates range",
                                      start = date.min,
                                      end = date.max,
                                      min = date.min,
                                      max = date.max)

fat.max <- max(dataset.tornadoes$fat)
slider.Tornadoes.fat <- sliderInput("fatalitiesTornadoes",
                                "Fatalities",
                                c(1,fat.max),
                                step = 1,
                                min = 0,
                                max = fat.max)

inj.max <- max(dataset.tornadoes$inj)
slider.Tornadoes.inj <- sliderInput("injuriesTornadoes",
                                    "Injuries",
                                    c(0,inj.max),
                                    step = 1,
                                    min = 0,
                                    max = inj.max)
wid.max <- max(dataset.tornadoes$wid)
slider.Tornadoes.wid <- sliderInput("widthTornado",
                                    "Width of a tornado [yards]",
                                    c(0,wid.max),
                                    step = 0.1,
                                    min = 0,
                                    max = wid.max)

len.max <- max(dataset.tornadoes$len)
slider.Tornadoes.len <- sliderInput("lengthTornado",
                                    "Track length [miles]",
                                    c(0,len.max),
                                    step = 0.1,
                                    min = 0,
                                    max = len.max)



tab.tornadoes <- tabItem(tabName = tab.name.tornadoes,
                         sidebarLayout(
                           sidebarPanel(
                               update.Tornadoes,
                               clear.Tornadoes,
                               select.Tornadoes,
                               dateRange.Tornadoes,
                               slider.Tornadoes.fat,
                               slider.Tornadoes.inj,
                               slider.Tornadoes.wid,
                               slider.Tornadoes.len),
                          mainPanel(leafletOutput(tornadoMapOutput))),
                         box(fluidRow(column(selectInput("statSelectTornado",
                                                         choices = c("Both" = "both",
                                                                     "Injuries" = "inj",
                                                                     "Fatalities" = "fat"),
                                                         selected = "both",
                                                         label = "Plot injuries or fatalities?"),
                                             plotOutput(tornadoStateStats),width=7),
                                  column(plotlyOutput("tornadoWidthStats"),
                                         actionButton("showSelectedTornadoes","Show selected"),
                                         actionButton("clearSelectedTornaodes","Clear Selected"),width=4)),width="100vw")
)

# body

dbBody <- dashboardBody(
  tabItems(
    tab.forecast,
    tab.specific,
    tab.tornadoes,
    tab.about
  )
)


# render page

dashboardPage(
  dbHeader,
  dbSidebar,
  dbBody,
  title = "Weather Report",
  skin = "green"
)
