# gloss bench figure patchwork-013
# source: web-map-choropleth-quantile.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set(warning = FALSE, message = FALSE)
# ---- chunk 2 ----
library(patchwork)   # To assemble plots
library(scico)       # For color gradients
library(sf)          # To handle vector map objects
library(tidyverse)   # For everything else ;)
# ---- chunk 3 ----
# Load data
map<-read_sf('data/price_map_france.gpkg')
# This map is only for department borders
fr<-sf::read_sf('data/france_sport.gpkg')

# Take a look at first lines
head(map)
# ---- chunk 4 ----
# Extract percentiles
bks<-quantile(map$price_ha,na.rm=TRUE,probs=seq(0,1,0.1))

# Add classes based on price of land for each region 
map_cl<-map%>%
  mutate(cl=case_when(
    price_ha<bks[2]~"A", 
    price_ha<bks[3]~"B",
    price_ha<bks[4]~"C",
    price_ha<bks[5]~"D",
    price_ha<bks[6]~"E",
    price_ha<bks[7]~"F",
    price_ha<bks[8]~"G",
    price_ha<bks[9]~"H",
    price_ha<bks[10]~"I",
    price_ha<=bks[11]~"J",
    TRUE~NA
  ))

# ---- chunk 5 ----
# Create color palette
pl<-rev(scico(10, palette = 'bam'))

# Set color for each class
pal<-c(
  "A"=pl[1],
  "B"=pl[2],
  "C"=pl[3],
  "D"=pl[4],
  "E"=pl[5],
  "F"=pl[6],
  "G"=pl[7],
  "H"=pl[8],
  "I"=pl[9],
  "J"=pl[10]
)

# Color for na values
na_col<-'grey50'
# Color for department borders 
col_border<-'#437C90'
# Create custom theme
custom_theme<-theme_void()+
  theme(plot.background = element_rect(fill="#202020",color=NA))

# ---- chunk 6 ----
# Make map
mp<-ggplot()+
  geom_sf(
    map_cl,
    mapping=aes(fill=cl,color=cl,geometry=geom),
  )+
  geom_sf(
    fr,
    mapping=aes(geometry=geom),
    fill=NA,color=col_border,linewidth=0.15,alpha=1
  )+
  scale_fill_manual(values=pal,na.value=na_col)+
  scale_color_manual(values=pal,na.value=na_col)+
  guides(fill='none',color="none")+
  custom_theme

mp

# ---- chunk 7 ----
# Set min value at 0 for color palette
bks[1]=0

tib<-tibble(
    end=bks
  )%>%
  mutate(
    start=lag(bks, 1),
    cl=c(0,"A","B","C","D","E",'F','G','H','I','J')
  )%>%
  # Remove first row
  slice(2:11)

# ---- chunk 8 ----
lg<-ggplot()+
  # Add color gradient
  ####################
  geom_rect(
    data=tib,
    aes(xmin=start,xmax=end,ymin=0,ymax=1,fill=cl)
  )+
  # Add labels
  geom_text(
    data=tib%>%slice(c(seq(1,10,2))),
    mapping=aes(x=start,y=1.1,label=start),
    angle=45,hjust=0,vjust=0,
    color="white"
  )+
  # Add points to show distribution
  #################################
  # Create one box behind points
  annotate(
    geom="rect",
    xmin=0,xmax=max(bks),ymin=-1.25,ymax=-0.25,
    fill=NA,color="dimgrey"
  )+
  geom_jitter(
    data=map_cl%>%st_drop_geometry(),
    mapping=aes(x=price_ha,y=-0.75,fill=cl,color=cl),
    pch=21,
    # Control jitter amplitude
    width=0,height=0.5
  )+
  scale_y_continuous(limits=c(-1.5,1.5))+
  scale_fill_manual(values=pal,na.value=na_col)+
  scale_color_manual(values=pal,na.value=na_col)+
  guides(fill='none',color='none')+
  custom_theme

lg

# ---- chunk 9 ----
# Define layout
layout <- c(
  area(t = 0, l = 0, b = 10, r = 10),
  area(t = 11, l = 0, b = 13, r = 10)
)

mp + lg +
  plot_layout(design = layout)+ 
  plot_annotation(
    title = 'The price of land',
    subtitle = 'The map below show the price of agricultural land, in euros per hectare.'
  )& 
  theme(
    plot.background = element_rect(fill="#202020",color=NA),
    text = element_text('mono',hjust=0.5,color="white"),
    plot.title = element_text(hjust=0.5,face='bold'),
    plot.subtitle = element_text(hjust=0.5)
  )
