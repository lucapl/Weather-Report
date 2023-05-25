#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shinydashboard)
library(leaflet)
library(DT)

tab.name.dashboard <- "dashboard"
tab.name.main.map <- "specificMap"
tab.name.about <- "about"


dbHeader <- dashboardHeader(title = div(icon("cloud-sun-rain")," Weather Report"),
                            tags$li(a(href = 'https://www.put.poznan.pl/',
                                      img(src = '/logo/PP_logotyp_ANG_CMYK.svg',
                                          title = "Poznań University Of Technology", height = "30px"),
                                      style = "padding-top:10px; padding-bottom:10px;"),
                                    class = "dropdown")
                            )

dbSidebar <- dashboardSidebar(sidebarMenu(
    menuItem("Dashboard", tabName = tab.name.dashboard, icon = icon("dashboard")),
    menuItem("Cool map", tabName = tab.name.main.map, icon = icon("map")),
    menuItem("About", tabName= tab.name.about, icon = icon("circle-info"))
  )
)

tab.about <- tabItem(
  tabName = tab.name.about,
  includeMarkdown("README.md")
)

dbBody <- dashboardBody(
  tabItems(
    # First tab content
    tabItem(tabName = tab.name.dashboard,
            fluidRow(
              box(plotOutput("plot1", height = 250)),
              
              box(
                title = "Controls",
                sliderInput("slider", "Number of observations:", 1, 100, 50)
              )
            )
    ),
    tabItem(tabName = tab.name.main.map,
            leafletOutput("myMap"),
            DTOutput('underMap')
    ),
    tab.about
  )
)

dashboardPage(
  dbHeader,
  dbSidebar,
  dbBody,
  skin = "green"
)
