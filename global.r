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
library(emojifont)

specificMapOutput <- "specificMapOutput"
underMapDtOutput <- "underMapDtOutput"
graphColumns <- "graphColumns"
graphColumnsButton <- "graphColumnsButton"
weatherOptions <- "weatherOptions"
tornadoMapOutput <- "tornadoMapOutput"
generalMapOutput <- "generalMapOutput"
tornadoStateStats <- "tornadoStateStats"
forecastMapOutput <- "forecastMapOutput"

#data processing

dataset.tornadoes <- read.csv("./data/us_tornado_dataset_1950_2021.csv")
tornado.pal <- brewer.pal(6,"YlGnBu")
names(tornado.pal) <- 0:5
#dataset.tornadoes <- dataset.tornadoes[sample.int(nrow(dataset.tornadoes)),]

dataset.tornadoes %>%
  mutate(date = as.Date(date)) %>%
  mutate(iconUrl = paste0("./www/tornadoes/tornado_ef",mag,".svg")) %>%
  mutate(label = paste0("Date: ",date,"<br>Fatalities: ",fat," Injuries: ",inj,"<br>Started at: ",slat,"&nbsp",slon,"<br>Width: ",wid)) -> dataset.tornadoes
dataset.tornadoes$key <- row.names(dataset.tornadoes)

#weather icons

icon.map.day <- c()
icon.map.day[0:100] <- ""
icon.map.day[c(100,1,2,3,51,53,55,56,57)] <- emoji("sunny")

icon.map.night <- c()
icon.map.night[0:100] <- ""
icon.map.night[c(100,1,2,3,51,53,55,56,57)] <- emoji("crescent_moon")


icon.map.cloud <- c()
icon.map.cloud[0:100] <- ""
icon.map.cloud[c(1,2,3)] <- emoji("cloud")
icon.map.cloud[c(45,48)] <- emoji("fog")
icon.map.cloud[c(51,53,55,56,57,61,63,64,66,67)] <- emoji("cloud_with_rain")
icon.map.cloud[c(71,73,75,77)] <- emoji("cloud_with_snow")
icon.map.cloud[c(80,81,82)] <- emoji("cloud_with_rain")
icon.map.cloud[c(85,86)] <- emoji("snowflake")
icon.map.cloud[c(95,96,99)] <- emoji("cloud_with_lightning_and_rain")
