## ---------------------------
##
## Script name: 
##
## Purpose of script: TO sort through water quality monitors in the UCRB and look for suspended sediment and turbidity and to check the quality of these data to make sure they are up to a certain bar.
##
## Author: Dr. Matthew Morriss
##
## Date Created: 2020-07-13
##
## Copyright (c) Matthew C Morriss,
## Email: matthew.c.morriss@gmail.com
##
## ---------------------------
##
## Notes: The goals for this code are the following:
## Combine the many different excel files for air quality measurements in salt lake city over the last 10 years.


## set working directory for PC ####

setwd('C:\\Users\\mmorriss\\Desktop\\SLC_aq')

## Load Libraries ####

library(openxlsx)
library(tidyverse)
library(lubridate)
library(purr)

## Setup variables and merge data ####
path <- "'C:\\Users\\mmorriss\\Desktop\\SLC_aq"
mergedName <- "'C:\\Users\\mmorriss\\Desktop\\SLC_aq\\merged.csv"
filenames_list <- list.files(pattern = "*.csv" )


All <- lapply(filenames_list,function(filename){
  print(paste("Merging",filename,sep = " "))
  read.csv(filename)
})


df <- do.call(rbind.data.frame, All)

write.csv(df,'10Yr_SLC_airquality.csv')