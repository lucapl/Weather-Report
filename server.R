#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)
library(shinydashboard)
library(leaflet)
library(httr)
#library(reshape2)
library(ggplot2)
library(dplyr)
library(tidyr)
library(plotly)
library(chron)

open.meteo <- "https://api.open-meteo.com/v1/"
response <- NULL
columns <- NULL

lists.to.dF <- function(lists){
  return(as.data.frame(do.call(cbind,lists)) %>% mutate_each(unlist))
}


function(input,output){
  # set.seed(122)
  # histdata <- rnorm(500)
  # 
  # output$plot1 <- renderPlot({
  #   data <- histdata[seq_len(input$slider)]
  #   hist(data)
  # })
  # 
  #map.specific <- get(map.specific.output,output) 
  output$specificMapOutput <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%  # Add default OpenStreetMap map tilesi
      setView(lat = 52.4036, lng = 16.95, zoom = 32)
      #addMarkers(lng=174.768, lat=-36.852, popup="The birthplace of R")
  })
  
  #paste0("input$",map.specific.output,"_click"),
  observeEvent(input$specificMapOutput_click, {
    click <- input$specificMapOutput_click
    if (is.null(click)) {
      return (NULL)
    }
    
    ## get coords
    lng <- click$lng
    lat <- click$lat

    request.lng <- lng %% 360
    if(lng < 0){
      request.lng <- -request.lng
    }
    
    ## Render marker
    specificMapOutput %>%
    leafletProxy() %>%
      clearMarkers() %>%
      addMarkers(lng = lng, lat = lat, popup=paste("lat",lat,"lng",lng))  # Add a marker at the clicked location
    #print(paste0("&hourly=",paste(c(input$weatherOptions),collapse=",")))
    
    ## get data
    response <<- GET(paste0(open.meteo,
                          "forecast?latitude=",lat,
                          "&longitude=",request.lng,
                          paste0("&hourly=",paste(c(input$weatherOptions),collapse=","))
                          ))
    response <<- lists.to.dF(content(response)$hourly)
    
    response %>%
      mutate(time=strptime(time,"%Y-%m-%dT%H:%M")) %>%
      mutate(time=as.POSIXct(time)) ->> response
    print(head(response))
    
    ## render data table
    output$underMapDtOutput <- renderDT(
      response,
      extensions = 'Select', 
      selection = list(target = "column"),
      options = list(ordering = FALSE, 
                     searching = FALSE, 
                     pageLength = 25)
    
    )
  })
  
  observeEvent(input$underMapDtOutput_columns_selected,{
    columns <<- response[,input$underMapDtOutput_columns_selected]
    print(columns)
  })
  
  observeEvent(input$graphColumnsButton,{
    output$graphColumns <- renderPlot({
      columns %>%
        rename(x = 1,
               y = 2) %>%
        select(x,y) %>%
      #print(columns)
      #melted <- melt(columns,1)
      #df.names <- labels(columns)
        ggplot(aes(
          x = x,
          y = y
        )) +
        geom_line()
    }) 
  })
}


