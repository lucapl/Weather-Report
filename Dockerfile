FROM rocker/shiny:4.2.1
RUN install2.r rsconnect tibble dplyr stringr rtweet htmltools lubridate bslib reactable
WORKDIR /home/shinytweet
COPY ui.R ui.R 
COPY server.R server.R 
COPY global.r global.r
COPY deploy.r deploy.r
RUN mkdir www
COPY www/* www/
COPY data/ data/
CMD Rscript deploy.r