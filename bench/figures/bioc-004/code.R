# gloss bench figure bioc-004
# source: NOISeq (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
### R code from vignette source 'NOISeq.Rnw'

###################################################
# ---- chunk 2 ----
### code chunk number 1: options
###################################################
options(digits=3, width=95)


###################################################
# ---- chunk 3 ----
### code chunk number 2: data
###################################################
library(NOISeq)
data(Marioni)


###################################################
# ---- chunk 4 ----
### code chunk number 3: NOISeq.Rnw:88-89
###################################################
head(mycounts)


###################################################
# ---- chunk 5 ----
### code chunk number 4: factors
###################################################
myfactors = data.frame(Tissue=c("Kidney","Liver","Kidney","Liver","Liver","Kidney","Liver",
                                "Kidney","Liver","Kidney"),
                       TissueRun = c("Kidney_1","Liver_1","Kidney_1","Liver_1","Liver_1",
                                     "Kidney_1","Liver_1","Kidney_2","Liver_2","Kidney_2"),
                       Run = c(rep("R1", 7), rep("R2", 3)))
myfactors


###################################################
# ---- chunk 6 ----
### code chunk number 5: NOISeq.Rnw:119-123
###################################################
head(mylength)
head(mygc)
head(mybiotypes)
head(mychroms)


###################################################
# ---- chunk 7 ----
### code chunk number 6: readData
###################################################
mydata <- readData(data=mycounts,length=mylength, gc=mygc, biotype=mybiotypes,
                   chromosome=mychroms, factors=myfactors)
mydata


###################################################
# ---- chunk 8 ----
### code chunk number 7: NOISeq.Rnw:152-156
###################################################
str(mydata)
head(assayData(mydata)$exprs)
head(pData(mydata))
head(featureData(mydata)@data)


###################################################
# ---- chunk 9 ----
### code chunk number 8: readData2
###################################################
mydata <- readData(data=mycounts,chromosome=mychroms, factors=myfactors)


###################################################
# ---- chunk 10 ----
### code chunk number 9: readData3
###################################################
mydata <- addData(mydata, length=mylength, biotype=mybiotypes, gc = mygc)


###################################################
# ---- chunk 11 ----
### code chunk number 10: dat
###################################################
myexplodata <- dat(mydata, type = "biodetection")
explo.plot(myexplodata, plottype = "persample")


###################################################
# ---- chunk 12 ----
### code chunk number 11: nicedata
###################################################
mynicedata <- dat2save(myexplodata)


###################################################
# ---- chunk 13 ----
### code chunk number 12: fig_biodetection
###################################################
mybiodetection <- dat(mydata, k = 0, type = "biodetection", factor = NULL)
par(mfrow = c(1,2))  # we need this instruction because two plots (one per sample) will be generated
explo.plot(mybiodetection, samples=c(1,2), plottype = "persample")


###################################################
# ---- chunk 14 ----
### code chunk number 13: fig_biodetection2
###################################################
par(mfrow = c(1,2))  # we need this instruction because two plots (one per sample) will be generated
explo.plot(mybiodetection, samples=c(1,2), toplot = "protein_coding", plottype = "comparison")


###################################################
# ---- chunk 15 ----
### code chunk number 14: fig_boxplot1
###################################################
mycountsbio = dat(mydata, factor = NULL, type = "countsbio")
explo.plot(mycountsbio, toplot = 1, samples = 1, plottype = "boxplot")


###################################################
# ---- chunk 16 ----
### code chunk number 15: fig_sat1
###################################################
mysaturation = dat(mydata, k = 0, ndepth = 7, type = "saturation")
explo.plot(mysaturation, toplot = 1, samples = 1:2, yleftlim = NULL, yrightlim = NULL)
