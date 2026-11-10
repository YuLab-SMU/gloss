# gloss bench figure gallery-012
# source: web-extended-dumbbell-plot-ggplot2.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
library(tidyverse)
library(ggtext)
library(extrafont)
# ---- chunk 3 ----
# font_import()  #run once
loadfonts(device = "win") #run once per session
# ---- chunk 4 ----
hbcu_all <- readr::read_csv('data/hbcu_all.csv')
# ---- chunk 5 ----
head(hbcu_all)
# ---- chunk 6 ----
hbcu_all %>%
  filter(Year >= 1990) %>% #filter the year
  select(Year, Males, Females)%>% #select columns of interest
  mutate(diff = Females - Males) %>% #calculate difference
  pivot_longer(cols = c(Males, Females)) %>% #get into long format
  rename(Gender = name, #rename columns
         Enrollments = value)-> dat_gender
head(dat_gender)
# ---- chunk 7 ----
  
Males <- dat_gender %>%
  filter(Gender == "Males")
Females <- dat_gender %>%
  filter(Gender == "Females")
head(Females)
# ---- chunk 8 ----
p <- ggplot(dat_gender)+
  
 geom_segment(data = Males,
              aes(x = Enrollments, y = Year,
                  yend = Females$Year, xend = Females$Enrollments), #use the $ operator to fetch data from our "Females" tibble
              color = "#aeb6bf",
              size = 4.5, #Note that I sized the segment to fit the points
              alpha = .5) +
  
  geom_point(aes(x = Enrollments, y = Year, color = Gender), size = 4, show.legend = TRUE)+
  
ggtitle("Enrollment Trends at Historically Black Colleges and Universities")
p
