#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#



# consts

open.meteo <- "https://api.open-meteo.com/v1/"
response <- NULL
columns <- NULL

# functions

lists.to.dF <- function(lists){
  return(as.data.frame(do.call(cbind,lists)) %>% mutate_each(unlist))
}

# main

function(input,output){
  
  #############
  #general tab
  output$generalMapOutput <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lat = 52.4036, lng = 16.95, zoom = 1)
  })
  
  observeEvent(input$updateGeneral,{
    rast <- raster(nrows=180,
                   ncols=360,
                   xmx=180,
                   ymn=-90,
                   ymx=90)
    rast <- setValues(rast,1:ncell(rast))
    crs(rast) <- "+proj=longlat +datum=WGS84"
    
    print(rast)
    
    pal <- colorNumeric(c("#0C2C84", "#41B6C4", "#FFFFCC"), values(rast),
                 na.color = "transparent")
    
    generalMapOutput %>%
      leafletProxy() %>%
      addRasterImage(rast,colors=pal,opacity = 1) 
    # %>%
    #   addLegend(pal=pal,values = values(rast))
  })
  
  #############
  # tornado tab
  
  tornado.pal.leaf <- colorFactor(
    "YlGnBu",0:5
  )
  
  output$tornadoMapOutput <- renderLeaflet({
    leaflet(dataset.tornadoes) %>%
      addTiles() %>%  # Add default OpenStreetMap map tilesi
      setView(lat = 35.4819, lng = -97.5084, zoom = 4) %>%
      addLegend("bottomright",
                data = 0:5,
                values = 0:5,
                pal=tornado.pal.leaf,
                title="Tornado Magnitude",
                labFormat = labelFormat(prefix="F/EF "),
                opacity = 0.9)
  })
  
  ## clear
  
  observeEvent(input$clearTornadoes, {
    tornadoMapOutput %>%
      leafletProxy() %>%
      clearMarkers() %>%
      clearShapes()
  })
  
  ## update
  
  observeEvent(input$updateTornadoes, {
    a.mag <- as.integer(input$selectTornadoes)
    daterange <- input$dateRangeTornadoes
    date.min <- daterange[1]
    date.max <- daterange[2]
    fat.range <- input$fatalitiesTornadoes
    fat.max <- as.integer(fat.range[2])
    fat.min <- as.integer(fat.range[1])
    inj.range <- input$injuriesTornadoes
    inj.max <- as.integer(inj.range[2])
    inj.min <- as.integer(inj.range[1])
    
    
    dataset.tornadoes %>%
      filter(mag %in% a.mag) %>%
      filter(date <= date.max & date >= date.min) %>%
      filter(fat <= fat.max & fat >= fat.min) %>%
      filter(inj <= inj.max & inj >= inj.min) -> subsetData
    #print(subsetData)
    output$tornadoStateStats <- renderPlot({
      subsetData %>%
        ggplot(aes(date)) +
        geom_point(aes(y = inj), color = "orange") +
        geom_point(aes(y = fat), color = "red") +
        facet_geo(~ st, grid = "us_state_grid2", label = "name") +
        ylab("Injuries and fatalities") +
        xlab("Date of occurence") +
        scale_x_continuous(labels = function(x) paste0("'", substr(x, 3, 4)))
       # scale_x_continuous(labels = function(x) paste0("'", substr(x, 3, 4))) +
        # labs(title = "Seasonally Adjusted US Unemployment Rate 2000-2016",
        #      caption = "Data Source: bls.gov",
        #      x = "Year",
        #      y = "Unemployment Rate (%)") +
        #theme(strip.text.x = element_text(size = 6))
    })#,width=678,height=384)
    
    output$tornadoWidthStats <- renderPlot({
      subsetData %>%
        ggplot(aes(len,
                   wid,
                   color=factor(mag))) +
        geom_point(aes(size=5)) +
        scale_color_manual(name = "Tornado magnitude: ",
                           values = tornado.pal,
                           breaks = 0:5) +
        scale_size(guide = "none") +
        ylab("Tornado width [yards]") +
        xlab("Lenght of the path travelled [miles]")
    })
  
    tornadoMapOutput %>%
      leafletProxy() -> map
    
    map %>%
      clearShapes() %>%
      addMarkers(lat = subsetData$slat,
                 lng =  subsetData$slon,
                 popup = subsetData$label,
                 group = subsetData$mag,
                 icon = makeIcon(iconUrl = subsetData$iconUrl,
                                 iconWidth = 12,
                                 iconHeight = 12)) %>%
      addCircles(lat = subsetData$elat,
                 lng = subsetData$elon,
                 label = paste("Ended at",subsetData$elat,subsetData$elon))-> map
    
    for(i in 1:nrow(subsetData)){
      row <- subsetData[i,]
      elon <- row$elon
      slon <- row$slon
      elat <- row$elat
      slat <- row$slat
      if (elon == 0 && elat == 0){
        map <- addCircles(map,
                          radius = 1609.34* row$len,
                          lat = slat, 
                          lng = slon,
                          color="red",
                          label = paste0("Ended somewhere: ",row$len," miles away"),
                          highlightOptions = highlightOptions(bringToFront = T))
                          
        next
      }
      map <- addPolylines(map, 
                          lat = c(slat,elat), 
                          lng = c(slon,elon),
                          color="red",
                          label = paste0("Length: ",row$len," miles"),
                          highlightOptions = highlightOptions(sendToBack = T))
    }
      
  })
  
  ###############
  # datatable tab
  
  output$specificMapOutput <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%  # Add default OpenStreetMap map tilesi
      setView(lat = 52.4036, lng = 16.95, zoom = 32)
    #addMarkers(lng=174.768, lat=-36.852, popup="The birthplace of R")
  })

  ## click map
  
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
    response <<- reactive({GET(paste0(open.meteo,
                          "forecast?latitude=",lat,
                          "&longitude=",request.lng,
                          paste0("&hourly=",paste(c(input$weatherOptions),collapse=","))
                          ))})()
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
  
  ## click datatable
  
  observeEvent(input$underMapDtOutput_columns_selected,{
    columns <<- response[,input$underMapDtOutput_columns_selected]
  })
  
  ## graph columns
  
  observeEvent(input$graphColumnsButton,{
    output$graphColumns <- renderPlot({
      columns %>%
        rename(x = 1,
               y = 2) %>%
        dplyr::zselect(x,y) %>%
      #print(columns)
      #melted <- melt(columns,1)
      #df.names <- labels(columns)
        ggplot(aes(
          x = x,
          y = y
        )) +
        geom_line() +
        xlab(colnames(columns)[1]) + 
        ylab(colnames(columns)[2])
    }) 
  })
}


