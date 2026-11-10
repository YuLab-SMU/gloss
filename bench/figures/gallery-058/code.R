# gloss bench figure gallery-058
# source: 24-boxplot-with-variable-width.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# Dummy data
names <- c(rep("A", 20) , rep("B", 8) , rep("C", 30), rep("D", 80))
value <- c( sample(2:5, 20 , replace=T) , sample(4:10, 8 , replace=T), 
       sample(1:7, 30 , replace=T), sample(3:8, 80 , replace=T) )
data <- data.frame(names,value)
 
# Calculate proportion of each level
proportion <- table(data$names)/nrow(data)
 
#Draw the boxplot, with the width proportionnal to the occurence !
boxplot(data$value ~ data$names , width=proportion , col=c("orange" , "seagreen"))
