install.packages(c("shiny","DT","shinydashboard","leaflet","httr","ggplot2","dplyr","tidyr","plotly","chron","raster","geofacet","RColorBrewer","htmltools","emojifont"))
library(rsconnect)
# Authenticate
setAccountInfo(name = Sys.getenv("SHINY_ACC_NAME"),
               token = Sys.getenv("TOKEN"),
               secret = Sys.getenv("SECRET"))
# Deploy
deployApp(appFiles = c("ui.R", "server.R", "global.r","www/","data/","README.md"),
          appName="Weather-Report",
          appSourceDoc = "www/*")
