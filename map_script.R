#install.packages('leaflet')


library(leaflet)
library(shiny)
# basic map ----
m <- leaflet() %>% 
  addTiles()%>%
  setView(-120, 55, zoom = 5)
m

#Aside: Viewer not working? Use Shiny! ---- 
currentMap <- m
library(shiny)
ui <- fluidPage(
  titlePanel("Interactive Leaflet Map"),
  mainPanel(
    leafletOutput("map",height=750,width=1200)
  )
)

server <- function(input, output, session) {
  output$map <- renderLeaflet(currentMap)
}

shinyApp(ui = ui, server = server)

# Add Markers Manually ----
m = m %>% addMarkers(lng = -123.1, lat = 49.3) #Add marker for Vancouver!
m

# Add markers from a dataset ----
#Import cities and filter for AB and BC
cities <- read.csv('data/cities/canadacities.csv')
cities <- cities[cities$province_id == "BC" | cities$province_id == "AB",]

#Add Markers for each city
m_city <- leaflet() %>% 
  addTiles() %>% 
  setView(-120, 55, zoom = 5) %>%
  addMarkers(data = cities,
             lng = ~lng, lat = ~lat, #use the 'lng' and 'lat' columns to demark locations
             popup = ~city,label=~city)
m_city

#Let's customize these points ---- 
province_palette <- colorFactor(c("blue","red"), domain = c("AB","BC")) #Create colour palette

m_city_colours <- leaflet() %>%
  addTiles() %>% 
  setView(-120, 55, zoom = 5) %>%
  addCircleMarkers(data=cities,
                   lng = ~lng, lat = ~lat, #Again, use lng and lat columns
                   color = ~province_palette(province_id), #Make colour based on province
                   radius = ~sqrt(population) * 0.01, #Make radius based on population of city
                   fillOpacity = 1.0 #Make each point opaque
  )
m_city_colours

#Dealing with Polygons! ----
library(sf) #to import and work with shapefiles
library(dplyr)
fires <- read_sf('data/historical_fires/PROT_HISTORICAL_FIRE_POLYS_SP.geojson') #import fires data. May take a couple mins to load
fires <- fires %>% 
  filter(FIRE_SIZE_HECTARES > 50000) %>% #filter for large fires
  select(FIRE_NUMBER,FIRE_YEAR,FIRE_SIZE_HECTARES, FIRE_CAUSE, geometry) #simplify columns


fires_proj <- st_transform(fires, 4326) #project to WSG 84 (so )
st_crs(fires_proj) #check in console that projection worked properly



 

# Customization ----
#create colour palette
fires_palette <- colorFactor(c("blue","red"),domain = c("Lightning","Person"))

fires_proj <- fires_proj %>% 
  #create label that combines fire size and year started into 1 string.
  mutate(label = paste(
    "Fire Size:", FIRE_SIZE_HECTARES, "Hectares |",
    "Year Started:", FIRE_YEAR)
    )
#Create the map!
m_fires2 <- leaflet(fires_proj) %>% 
  addTiles() %>% 
  setView(-120, 55, zoom = 5) %>%
  addPolygons(stroke = FALSE, #remove outer stroke
              fillOpacity = 1.0, #100% opacity
              color = ~fires_palette(FIRE_CAUSE), #colour using our custom palette
              label = ~label #use the labels we created earlier 
  ) %>%
  addLegend("bottomleft", #put legend in top right
            pal = fires_palette, #use the fires palette colours
            values = ~FIRE_CAUSE, #use the fire cause values
            title = "Fire Causes (BC)", #Title of legend
            opacity = 1 #legend should be opaque
  ) %>%
  addScaleBar(position = "topright",
              options = scaleBarOptions(imperial = FALSE))
currentMap <- m_fires2
  


#test these rats
# Plot using ggplot2
ggplot(data = fires_proj) +
  geom_sf(fill = "red", color = "black", alpha = 0.5) +
  theme_minimal() +
  labs(title = "Historical Fires (Filtered by Size)",
       subtitle = "Polygons with FEATURE_AREA_SQM > 300,000,000",
       caption = "Source: PROT_HISTORICAL_FIRE_POLYS_SP.geojson")
#template to save as htm;
library(htmlwidgets)
saveWidget(m, file="maps/m1.html")

