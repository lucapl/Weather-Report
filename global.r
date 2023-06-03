specificMapOutput <- "specificMapOutput"
underMapDtOutput <- "underMapDtOutput"
graphColumns <- "graphColumns"
graphColumnsButton <- "graphColumnsButton"
weatherOptions <- "weatherOptions"
tornadoMapOutput <- "tornadoMapOutput"

#data processing

dataset.tornadoes <- read.csv("./data/us_tornado_dataset_1950_2021.csv")
#dataset.tornadoes <- dataset.tornadoes[sample.int(nrow(dataset.tornadoes)),]
dataset.tornadoes 

dataset.tornadoes %>%
  mutate(date = as.Date(date)) %>%
  mutate(iconUrl = paste0("./www/tornadoes/tornado_ef",mag,".svg")) %>%
  mutate(label = paste0("Date: ",date," Fatalities: ",fat," Injuries: ",inj)) -> dataset.tornadoes
