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

setwd('/Users/matthew/Documents/GitHub/SLC_aq')

## Load Libraries ####
rm(list = ls())
library(openxlsx)
library(tidyverse)
library(lubridate)
library(RColorBrewer)
library(tsibble)
# library(purr)


##########M Merge Data  ############
path <- "'/Users/matthew/Documents/GitHub/SLC_aq"
mergedName <- "'/Users/matthew/Documents/GitHub/SLC_aq/merged.csv"
filenames_list <- list.files(pattern = "*.csv" )


All <- lapply(filenames_list,function(filename){
  print(paste("Merging",filename,sep = " "))
  read.csv(filename)
})


df <- do.call(rbind.data.frame, All)

write.csv(df,'10Yr_SLC_airquality.csv')

# load Data ####

df <- read.csv('10Yr_SLC_airquality.csv')

## Plot whole history ###

df$Date <- mdy(df$Date)

df <- df %>%
  mutate(year = year(Date))%>%
  mutate(doy = yday(Date)) %>%
  arrange(year,doy) %>%
  distinct(year,doy, .keep_all = TRUE) %>%
  group_by(year) %>%
  mutate(aqi_sum = cumsum(DAILY_AQI_VALUE))

dfS <- df %>%
  filter(doy > 90)%>%
  mutate(aqi_sum = cumsum(DAILY_AQI_VALUE))

#####
df %>%
  group_by(year) %>%
  ggplot(aes(y = DAILY_AQI_VALUE,
             x = doy,
             color = year))+
  # geom_smooth(se=FALSE)+
  geom_point()


#####
hm.palette <- colorRampPalette(rev(brewer.pal(11, 'Spectral')), space='Lab')
df %>%
  group_by(year) %>%
  # mutate(year = year(Date))%>%
  mutate(doy = yday(Date)) %>%
  ggplot(aes(x = doy, y = year, fill = DAILY_AQI_VALUE))+
  geom_tile()+
  scale_fill_gradientn(colours = hm.palette(100),
                       # trans = "log",
                       name = 'Daily AQI')+
  labs(x = 'Day of Year',y = 'Year')+
  geom_vline(xintercept = c(87,151))+
  theme_light()

################### Calculate 10 year average pre-2020 ######
df2020 <- df %>% filter(year == 2020) 
df %>%
  filter(year != 2020) %>%
  group_by(doy) %>%
  summarize(meanAQI = median(DAILY_AQI_VALUE),sdAQI = sd(DAILY_AQI_VALUE))%>%
  
  ggplot(aes(x = doy, y = meanAQI))+
  geom_line()+
  geom_line(aes(x = doy, y = (meanAQI-sdAQI)), size = 0.4,
                color = 'gray')+
  geom_line(aes(x = doy, y = (meanAQI+sdAQI)), size = 0.4,
                color = 'gray')+
  geom_line(data = df2020,aes(x = doy, y = DAILY_AQI_VALUE),
            size = 0.4,
            color = 'red')

########### Plot cumulative sum by year #############
# hm.palette <- colorRampPalette(rev(brewer.pal(11, 'Spectral')), space='Lab')
df %>%
  ggplot(aes(x = doy, y = aqi_sum, color = year))+
  geom_point()+
  theme_light()+
  labs(x = "Day of Year", y = "Cumulative sum (AQI)", color = "Year")+
  scale_color_gradientn(colours = hm.palette(100),
                       # trans = "log",
                       name = 'Year')+
  geom_vline(xintercept = c(87,151))
  # xlim(1,180)

########## Shortened cumulative sum#############
dfS %>%
  ggplot(aes(x = doy, y = aqi_sum, color = year))+
  geom_point()+
  theme_light()+
  labs(x = "Day of Year", y = "Cumulative sum (AQI)", color = "Year")+
  scale_color_gradientn(colours = hm.palette(100),
                        # trans = "log",
                        name = 'Year')+
  geom_vline(xintercept = c(87,151))
# xlim(1,180)


########## Cumulative plot colored by AQI #############

hm.palette <- colorRampPalette(rev(brewer.pal(11, 'Spectral')), space='Lab')
dfS %>%
  ggplot(aes(x = doy, y = aqi_sum, color = DAILY_AQI_VALUE))+
  geom_point()+
  theme_light()+
  labs(x = "Day of Year", y = "Cumulative sum (AQI)", color = "Year")+
  scale_color_gradientn(colours = hm.palette(100),
                        # trans = "log",
                        name = 'Daily AQI')+
  geom_vline(xintercept = c(87,151))

########## Cumulative plot by year (faceted #############
hm.palette <- colorRampPalette(rev(brewer.pal(11, 'Spectral')), space='Lab')
dfS %>%
  ggplot(aes(x = doy, y = aqi_sum, color = DAILY_AQI_VALUE))+
  geom_point()+
  theme_light()+
  labs(x = "Day of Year", y = "Cumulative sum (AQI)", color = "Year")+
  scale_color_gradientn(colours = hm.palette(100),
                        # trans = "log",
                        name = 'Daily AQI')+
  geom_vline(xintercept = c(87,151))+
  facet_wrap(~year)

##########  Convert data frame to a tsibble #############

df_tsibble <- as_tsibble(df,key = DAILY_AQI_VALUE, index = Date)

a <- df_tsibble %>%
  filter(., year != 2020) %>%
  index_by(week =~ week(.)) %>%
  summarize(
    avg_aqi = mean(DAILY_AQI_VALUE,na.rm= TRUE)
  ) %>%
  ggplot(aes(x = week,y = avg_aqi, color = year))+
  geom_smooth()+
  geom_line()
a