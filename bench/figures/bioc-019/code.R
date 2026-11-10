# gloss bench figure bioc-019
# source: flowPlots (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
### R code from vignette source 'flowPlots.Rnw'

###################################################
# ---- chunk 2 ----
### code chunk number 1: loadPackage
###################################################
library(flowPlots)


###################################################
# ---- chunk 3 ----
### code chunk number 2: profBP
###################################################
data(profileDF)
profileDataSubset = subset(profileDF, stim=="LPS" & concGroup==3 & cell=="mDC")
profileDataSubset[1:3,]
# Use data helper function, makeDataList()
groupDataList = makeDataList(profileDataSubset ,"group", 1:16)
# Make x-axis tick labels
data(markerMatrix)
theMarkers = colnames(markerMatrix)
xTickLabels = cbind(theMarkers, t(markerMatrix))


###################################################
# ---- chunk 4 ----
### code chunk number 3: flowPlots.Rnw:83-91
###################################################
GroupListBoxplot(groupDataList, xlabel="", 
   ylabel="Percent of All Cells", boxOutliers=FALSE,
   xAxisLabels=xTickLabels, xMtext="Marker Category", 
   mainTitle="Stimulation = LPS, Concentration Group = 3, Cell = mDC", 
   legendGroupNames=c("Adults","Neonates"), pointColor=c(2,4),    
   testTitleCEX=.8, nCEX=.6, pCEX=.6, legendColor=c(2,4), legendCEX=.6,
   xAxisCEX=.7, xAtMtext=-1)
mtext("PROFILE DATA", side=3, line=2)


###################################################
# ---- chunk 5 ----
### code chunk number 4: margBP
###################################################
data(marginalDF)
marginalDataSubset = subset(marginalDF, stim=="LPS" & concGroup==3 & cell=="mDC")
marginalDataSubset[1:3,]
# Use data helper function, makeDataList()
groupDataList = makeDataList(marginalDataSubset ,"group", 1:5)


###################################################
# ---- chunk 6 ----
### code chunk number 5: flowPlots.Rnw:111-118
###################################################
GroupListBoxplot(groupDataList, xlabel="Cytokine", 
   ylabel="Percent of All Cells", boxOutliers=FALSE,
   xAxisLabels=c("TNFa","IL6","IL12","IFNa","AnyMarker"), 
   mainTitle="Stimulation = LPS, Concentration Group = 3, Cell = mDC", 
   legendGroupNames=c("Adults","Neonates"), pointColor=c(2,4),    
   testTitleCEX=.8, nCEX=.8, pCEX=.8, legendColor=c(2,4), legendCEX=.7)
mtext("MARGINAL DATA", side=3, line=2)


###################################################
# ---- chunk 7 ----
### code chunk number 6: pfdBP
###################################################
data(pfdDF)
pfdDataSubset = subset(pfdDF, stim=="LPS" & concGroup==3 & cell=="mDC")
pfdDataSubset[1:3,]
# Use data helper function, makeDataList()
groupDataList = makeDataList(pfdDataSubset ,"group", 1:4)


###################################################
# ---- chunk 8 ----
### code chunk number 7: flowPlots.Rnw:138-144
###################################################
GroupListBoxplot(groupDataList, xlabel="Cytokine", 
   ylabel="Percent of Reactive Cells", boxOutliers=FALSE,
   mainTitle="Stimulation = LPS, Concentration Group = 3, Cell = mDC", 
   legendGroupNames=c("Adults","Neonates"), pointColor=c(2,4),    
   testTitleCEX=.8, nCEX=.8, pCEX=.8, legendColor=c(2,4), legendCEX=.7)
mtext("PFD DATA", side=3, line=2)


###################################################
# ---- chunk 9 ----
### code chunk number 8: pfd1BP
###################################################
data(pfdPartsList)
# Look at the composition percentages for the case where PFD=1
pfdEq1PartsDataSubset = subset(pfdPartsList[[1]], stim=="LPS" & concGroup==3 & cell=="mDC")
pfdEq1PartsDataSubset[1:3,]
# Use data helper function, makeDataList()
groupDataList = makeDataList(pfdEq1PartsDataSubset, "group", 1:4)


###################################################
# ---- chunk 10 ----
### code chunk number 9: flowPlots.Rnw:165-171
###################################################
GroupListBoxplot(groupDataList, xlabel="Cytokine", 
   ylabel="Percent of Cells With PFD=1", boxOutliers=FALSE,
   mainTitle="Stimulation = LPS, Concentration Group = 3, Cell = mDC", 
   legendGroupNames=c("Adults","Neonates"), pointColor=c(2,4),    
   testTitleCEX=.8, nCEX=.8, pCEX=.8, legendColor=c(2,4), legendCEX=.7)
mtext("COMPOSITION OF PFD=1 DATA", side=3, line=2)


###################################################
# ---- chunk 11 ----
### code chunk number 10: pfd2BP
###################################################
# Look at the composition percentages for the case where PFD=2
pfdEq2PartsDataSubset = subset(pfdPartsList[[2]], stim=="LPS" & concGroup==3 & cell=="mDC")
pfdEq2PartsDataSubset[1:3,]
# Use data helper function, makeDataList()
groupDataList = makeDataList(pfdEq2PartsDataSubset, "group", 1:6)


###################################################
# ---- chunk 12 ----
### code chunk number 11: flowPlots.Rnw:190-196
###################################################
GroupListBoxplot(groupDataList, xlabel="Cytokine", 
   ylabel="Percent of Cells With PFD=2", boxOutliers=FALSE,
   mainTitle="Stimulation = LPS, Concentration Group = 3, Cell = mDC", 
   legendGroupNames=c("Adults","Neonates"), pointColor=c(2,4),    
   testTitleCEX=.8, nCEX=.8, pCEX=.8, legendColor=c(2,4), legendCEX=.7)
mtext("COMPOSITION OF PFD=2 DATA", side=3, line=2)


###################################################
# ---- chunk 13 ----
### code chunk number 12: pfd3BP
###################################################
# Look at the composition percentages for the case where PFD=3
pfdEq3PartsDataSubset = subset(pfdPartsList[[3]], stim=="LPS" & concGroup==3 & cell=="mDC")
pfdEq3PartsDataSubset[1:3,]
# Use data helper function, makeDataList()
groupDataList = makeDataList(pfdEq3PartsDataSubset, "group", 1:4)


###################################################
# ---- chunk 14 ----
### code chunk number 13: flowPlots.Rnw:215-221
###################################################
GroupListBoxplot(groupDataList, xlabel="Cytokine", 
   ylabel="Percent of Cells With PFD=3", boxOutliers=FALSE,
   mainTitle="Stimulation = LPS, Concentration Group = 3, Cell = mDC", 
   legendGroupNames=c("Adults","Neonates"), pointColor=c(2,4),    
   testTitleCEX=.8, nCEX=.8, pCEX=.8, legendColor=c(2,4), legendCEX=.7)
mtext("COMPOSITION OF PFD=3 DATA", side=3, line=2)


###################################################
# ---- chunk 15 ----
### code chunk number 14: ternPlot
###################################################
data(pfdDF)
pfdDataSubset = subset(pfdDF, stim=="LPS" & concGroup==3 & cell=="mDC")
# Use data helper function, makeTernaryData() 
ternaryData = makeTernaryData(pfdDataSubset, 1, 2, 3:4)
colnames(ternaryData) = c("PFD1", "PFD2", "PFD3-4")
adultPFDData = subset(pfdDataSubset, group=="adult", select=c(PFD1:PFD4))
neoPFDData = subset(pfdDataSubset, group=="neonate", select=c(PFD1:PFD4))
groupPFDDataList = list(adultPFDData, neoPFDData)
pfdGroupStatsList = computePFDGroupStatsList(groupPFDDataList, pfdValues=1:4,
   numDigitsMean=3, numDigitsSD=2)
groupNames = c("Adults","Neonates")
legendNames = legendPFDStatsGroupNames(pfdGroupStatsList,groupNames)


###################################################
# ---- chunk 16 ----
### code chunk number 15: flowPlots.Rnw:248-255
###################################################
# Load the package, vcd, for the ternaryplot() fcn
library(vcd)
ternaryplot(ternaryData, cex=.5, col=as.numeric(pfdDataSubset$group)*2,  
   main="TERNARY PLOT OF PFD DATA,
Stimulation = LPS, Concentration Group = 3, Cell = mDC")
grid_legend(0.8, 0.7, pch=c(20,20), col=c(2,4), legendNames, 
   title = "Group (n), mean/sd:", gp=gpar(cex=.8))


###################################################
# ---- chunk 17 ----
### code chunk number 16: barPlot
###################################################
data(profileDF)
profileDataSubset = subset(profileDF, stim=="LPS" & concGroup==3 & cell=="mDC")
profileColumns = 1:16
# Use data helper function, makeBarplotData()
barplotData = makeBarplotData(profileDataSubset, profileColumns, groupVariableName="group")
barplotDataWithLegend = cbind(barplotData, NA, NA)
barColors = gray(0:15/15)[16:1]


###################################################
# ---- chunk 18 ----
### code chunk number 17: flowPlots.Rnw:276-281
###################################################
barplot(barplotDataWithLegend, col=barColors, 
main="Stimulation = LPS, Concentration Group = 3, Cell = mDC")
legendNames = rownames(barplotData)
legend(2.75,100,legend=legendNames[16:1],col=barColors[16:1],cex=.8,pch=20)
mtext("BAR PLOT OF PROFILE DATA", side=3, line=3)


###################################################
# ---- chunk 19 ----
### code chunk number 18: boxplotExample
###################################################
# Create Example data list
group1 = as.data.frame(cbind(rnorm(10,1.2,.6),rnorm(10,3.2,.8)))
group2 = as.data.frame(cbind(rnorm(10,1.2,.6),rnorm(10,3.2,.8)))
group3 = as.data.frame(cbind(rnorm(10,1.2,.6),rnorm(10,3.2,.8)))
group4 = as.data.frame(cbind(rnorm(10,1.2,.6),rnorm(10,3.2,.8)))
group5 = as.data.frame(cbind(rnorm(10,1.2,.6),rnorm(10,3.2,.8)))
dataList = list(group1,group2,group3,group4,group5) 
# Create pointColor list
colorGroup1 = cbind(c(rep(2,5),rep(4,5)),c(rep(2,5),rep(4,5)))
colorGroup2 = cbind(c(rep(2,5),rep(4,5)),c(rep(2,5),rep(4,5)))
colorGroup3 = cbind(c(rep(2,5),rep(4,5)),c(rep(2,5),rep(4,5)))
colorGroup4 = cbind(c(rep(2,5),rep(4,5)),c(rep(2,5),rep(4,5)))
colorGroup5 = cbind(c(rep(2,5),rep(4,5)),c(rep(2,5),rep(4,5)))
pointColorList = list(colorGroup1,colorGroup2,colorGroup3,colorGroup4, colorGroup5)


###################################################
# ---- chunk 20 ----
### code chunk number 19: flowPlots.Rnw:310-315
###################################################
GroupListBoxplot(dataList, xlabel="Cytokine", ylabel="Percent of CD4 Cells", 
xAxisLabels=c("IFNg","TNFa"), mainTitle="Compare Innate Immune Response", 
legendGroupNames=c("Female","Male"), legendColors=c(2,4), boxOutliers=FALSE,   
pointColor=pointColorList, testTitleCEX=.8, nCEX=.8, pCEX=.8)
text(3,3,"Groups 1-5 are plotted left to right")
