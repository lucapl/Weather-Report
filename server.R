#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

load.fontawesome()

# consts

open.meteo <- "https://api.open-meteo.com/v1/"
response <- NULL
forecastResponse <- NULL
columns <- NULL
subsetData <- NULL

# functions

lists.to.dF <- function(lists){
  return(as.data.frame(do.call(cbind,lists)) %>% mutate_each(unlist))
}

get.response <- function(lat,lng,options){
  to.return <- reactive({GET(paste0(open.meteo,
                                    "forecast?latitude=",lat,
                                    "&longitude=",lng,
                                    paste0("&hourly=",paste(c(options),collapse=","))
                                    ))})()
  to.return <- lists.to.dF(content(to.return)$hourly)
  
  to.return %>%
    mutate(time=strptime(time,"%Y-%m-%dT%H:%M")) %>%
    mutate(time=as.POSIXct(time)) -> to.return
  
  return(to.return)
}

click.map <- function(click,map.name){
  if (is.null(click)) {
    return (NULL)
  }
  
  ## get coords
  lng <- click$lng
  lat <- click$lat
  
  request.lng <- ifelse(lng>0,lng,-lng)%%180
  
  
  ## Render marker
  map.name %>%
    leafletProxy() %>%
    clearMarkers() %>%
    addMarkers(lng = lng, lat = lat, popup=paste("lat",lat,"lng",lng)) # Add a marker at the clicked location
  
  print(paste(lat,request.lng,lng))
  
  return(c(lat,request.lng))
}


weathercode.to.icon <- function(weathercode,is.day){
  new.vector <- c()
  for(i in 1:length(weathercode)){
    cloud <- icon.map.cloud[weathercode[i]]
    sun <- icon.map.day[weathercode[i]]
    if(is.day[i]==0){
      sun <- icon.map.night[weathercode[i]]
    }
    new.vector <- c(new.vector,paste0(sun,cloud,recycle0 = T))
  }
  return(new.vector)
}

# main

function(input,output){
  
  #############
  #general tab
  # output$generalMapOutput <- renderLeaflet({
  #   leaflet() %>%
  #     addTiles() %>%
  #     setView(lat = 52.4036, lng = 16.95, zoom = 1)
  # })
  # 
  # observeEvent(input$updateGeneral,{
  #   rast <- raster(nrows=180,
  #                  ncols=360,
  #                  xmx=180,
  #                  ymn=-90,
  #                  ymx=90)
  #   rast <- setValues(rast,1:ncell(rast))
  #   crs(rast) <- "+proj=longlat +datum=WGS84"
  #   
  #   print(rast)
  #   
  #   pal <- colorNumeric(c("#0C2C84", "#41B6C4", "#FFFFCC"), values(rast),
  #                na.color = "transparent")
  #   
  #   generalMapOutput %>%
  #     leafletProxy() %>%
  #     addRasterImage(rast,colors=pal,opacity = 1) 
  #   # %>%
  #   #   addLegend(pal=pal,values = values(rast))
  # })
  
  #############
  # forecast tab
  output$forecastMapOutput <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%  # Add default OpenStreetMap map tilesi
      setView(lat = 52.4036, lng = 16.95, zoom = 32)
    #addMarkers(lng=174.768, lat=-36.852, popup="The birthplace of R")
  })
  
  # click map
  observeEvent(input$forecastMapOutput_click, {
    click <- input$forecastMapOutput_click
    
    # mark click on map
    lat.lng <- click.map(click,forecastMapOutput)
    lat <- lat.lng[1]
    lng <- lat.lng[2]
    print(paste(lat,lng))
    
    ## get data
    forecastResponse <<- get.response(lat,lng,c("temperature_2m",
                                                "weathercode",
                                                "is_day",
                                                "windspeed_10m",
                                                "winddirection_10m"))
    forecastResponse %>%
      mutate(weathercode = ifelse(weathercode==0,100,weathercode)) %>%
      mutate(image = weathercode.to.icon(weathercode,is_day)) ->> forecastResponse
    
    output$forecastPlot <- renderPlot({
      forecastResponse %>%
      ggplot(aes(x=time,
                 y=temperature_2m)) +
        geom_line(color="red",size=2) +
        geom_label(aes(label=image),
                   family='EmojiOne',
                   size = 5,
                   data = . %>% 
                     filter(row_number() %% 6 == 0 | row_number() == 1))
    })
    output$windPlot <- renderPlot({
      forecastResponse %>%
        ggplot(aes(x=time,
                   y=windspeed_10m)) +
        geom_line(size=2,color="blue") +
        geom_text(aes(label="↑",
                      angle=winddirection_10m),
                  size = 10,
                  data = . %>% 
                    filter(row_number() %% 2 == 0 | row_number() == 1))
    })
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
    wid.range <- input$widthTornado
    wid.max <- as.integer(wid.range[2])
    wid.min <- as.integer(wid.range[1])
    len.range <- input$lengthTornado
    len.max <- as.integer(len.range[2])
    len.min <- as.integer(len.range[1])
    
    dataset.tornadoes %>%
      filter(mag %in% a.mag) %>%
      filter(date <= date.max & date >= date.min) %>%
      filter(fat <= fat.max & fat >= fat.min) %>%
      filter(len <= len.max & len >= len.min) %>%
      filter(wid <= wid.max & wid >= wid.min) %>%
      filter(inj <= inj.max & inj >= inj.min) ->> subsetData
    #print(subsetData)
    if(nrow(subsetData) == 0){
      return(1)
    }
    
    output$tornadoStateStats <- renderPlot({
      subsetData %>%
        ggplot(aes(date)) +
        geom_point(aes(y = inj), color = "orange") +
        geom_point(aes(y = fat), color = "red") +
        facet_geo(~ st, grid = "us_state_grid2") +
        ylab("Injuries and fatalities") +
        xlab("Date of occurence") +
        scale_x_date(labels = function(x) paste0("'", substr(x,3,4))) +
        scale_y_continuous(n.breaks=3,minor_breaks = NULL)
    })
    
    p <- NULL
    output$tornadoWidthStats <- renderPlotly({
      # subsetData %>%
      #   ggplot(aes(len,
      #              wid,
      #              color=factor(mag))) +
      #   geom_point(aes(size=5)) +
      #   scale_color_manual(name = "Tornado magnitude: ",
      #                      values = tornado.pal,
      #                      breaks = 0:5) +
      #   scale_size(guide = "none") +
      #   ylab("Tornado width [yards]") +
      #   xlab("Lenght of the path travelled [miles]")
      mags <- cut(abs(subsetData$mag),
                       breaks = 0:5)
      
      subsetData %>%
        plot_ly(x=~len,
                y=~wid,
                key=~key,
                color=~factor(mag),
                colors=tornado.pal) %>%
        layout(title = 'Tornado track to width comparison',
               plot_bgcolor='#e5ecf6',
               xaxis = list(title = 'Length of the path travelled [miles]',
                            zerolinecolor = '#ffff', 
                            zerolinewidth = 2, 
                            gridcolor = 'ffff'), 
               yaxis = list(title = 'Tornado Width [yards]',
                            zerolinecolor = '#ffff', 
                            zerolinewidth = 2, 
                            gridcolor = 'ffff'),
               legend = list(title=list(text='<b> Tornado magnitude </b>'),
                             bgcolor="e5ecf6")) ->> p
      
      p
    })
    
    event_register(p,event="plotly_selected")
    
    
  
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
  
  ## select tornado points
  
  observeEvent(input$showSelectedTornadoes,{
    #print(plotlyInput())
    tornadoMapOutput %>%
      leafletProxy() %>%
      clearGroup("selected") -> map.proxy
    
    selected <- event_data("plotly_selected")
    #print(selected)
    if(is.null(selected)){
      return(0)
    }
    dataset.tornadoes %>%
      slice(as.integer(selected$key)) -> selected

    map.proxy%>%
      addMarkers(icon=makeIcon(iconUrl = "./www/tornadoes/tornado_selected.svg",
                               iconWidth=16,
                               iconHeight=16),
                 group = "selected",
                 lat = selected$slat,
                 lng = selected$slon,
                 popup = selected$label)
    
  })
  
  ## clear selected
  
  observeEvent(input$clearSelectedTornaodes,{
    tornadoMapOutput %>%
      leafletProxy() %>%
      clearGroup("selected")
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

    # mark click on map
    lat.lng <- click.map(click,specificMapOutput)
    print(lat.lng)
    lat <- lat.lng[1]
    lng <- lat.lng[2]
   
    #print(paste0("&hourly=",paste(c(input$weatherOptions),collapse=",")))
    
    ## get data
    response <<- get.response(lng,lat,input$weatherOptions)
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
        dplyr::select(x,y) %>%
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


