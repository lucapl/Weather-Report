library(shiny)
library(DT)
library(shinydashboard)
library(leaflet)
library(httr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(plotly)
library(chron)
library(raster)
library(geofacet)
library(RColorBrewer)
library(htmltools)

specificMapOutput <- "specificMapOutput"
underMapDtOutput <- "underMapDtOutput"
graphColumns <- "graphColumns"
graphColumnsButton <- "graphColumnsButton"
weatherOptions <- "weatherOptions"
tornadoMapOutput <- "tornadoMapOutput"
generalMapOutput <- "generalMapOutput"
tornadoStateStats <- "tornadoStateStats"

#data processing

dataset.tornadoes <- read.csv("./data/us_tornado_dataset_1950_2021.csv")
tornado.pal <- brewer.pal(6,"YlGnBu")
#dataset.tornadoes <- dataset.tornadoes[sample.int(nrow(dataset.tornadoes)),]

dataset.tornadoes %>%
  mutate(date = as.Date(date)) %>%
  mutate(iconUrl = paste0("./www/tornadoes/tornado_ef",mag,".svg")) %>%
  mutate(label = paste0("Date: ",date,"<br>Fatalities: ",fat," Injuries: ",inj,"<br>Started at: ",slat,"&nbsp",slon)) -> dataset.tornadoes
