#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shinydashboard)
library(shiny)
library(leaflet)
library(DT)
library(plotly)

# consts

tab.name.dashboard <- "dashboard"
tab.name.main.map <- "specificMap"
tab.name.map.general <- "generalMap"
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
    menuItem("Forecast", tabName = tab.name.map.general, icon = icon("calendar-days")),
    menuItem("General Map", tabName = tab.name.map.general, icon = icon("map")),
    menuItem("Tornadoes in US", tabName = tab.name.tornadoes, icon = icon("tornado")),
    menuItem("Climate change", tabName = tab.name.climate, icon = icon("earth-europe")),
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

# datatable tab

weather.Options <- checkboxGroupInput(weatherOptions,
                                      "Weather options: ",
                                      c("Temperature" = "temperature_2m",
                                        "Humidity" = "relativehumidity_2m",
                                        "Rain" = "rain",
                                        "Snowfall" = "snowfall",
                                        "Cloudcover" = "cloudcover",
                                        "Visibility" = "visibility"),
                                        selected = c("temperature_2m")
)


tab.specific <- tabItem(tabName = tab.name.main.map,
                        leafletOutput(specificMapOutput),
                        weather.Options,
                        box(DTOutput(underMapDtOutput),width="100vw"),
                        actionButton(graphColumnsButton,"Graph Data"),
                        box(plotOutput(graphColumns,height = 250,width="100vw"),width="100vw")
)

# tornado tab

select.Tornadoes <- selectInput("selectTornadoes",
                                "Tornado strength (Enchanced Fujita Scale): ",
                                c("EF0" = 0,"EF1" = 1,"EF2" = 2,"EF3" = 3,"EF4" = 4,"EF5" = 5),
                                "EF2"
)
update.Tornadoes <- actionButton("updateTornadoes",
                                 "Update")
clear.Tornadoes <- actionButton("clearTornadoes",
                                "Clear")

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


tab.tornadoes <- tabItem(tabName = tab.name.tornadoes,
                         leafletOutput(tornadoMapOutput),
                         update.Tornadoes,
                         clear.Tornadoes,
                         select.Tornadoes,
                         dateRange.Tornadoes,
                         slider.Tornadoes.fat,
                         slider.Tornadoes.inj)

# body

dbBody <- dashboardBody(
  tabItems(
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
