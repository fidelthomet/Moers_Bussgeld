rm(list = ls()) 
setwd("~/Desktop/R/Moers_Bussgeld/")

require(ckanr)
require(RCurl)

ckanr_setup(url = "https://www.offenesdatenportal.de/")

# search for "Bußgelder Ruhender Verkehr Moers" to obtain package IDs
# package_search("Bußgelder Ruhender Verkehr Moers") 

bs_15_url <- package_show("a5413176-635e-4b18-9e2c-abf3a3237de2", as="table")$resources$url
bs_15 <- read.csv2(text = getURL(bs_15_url))

# rename columns
names(bs_15) <- c("date", "time", "tatort", "tatbestand", "busse")

# import geocoded adresses
moers_adresses <- read.csv("Moers_Falschparker.csv", sep = "\t", stringsAsFactors=FALSE)

# merge datasets
bs_15 <- merge(bs_15,moers_adresses,by = "tatort")

# dump not geocoded adresses
bs_15 <- bs_15[!is.na(bs_15$lat),]

# dump geocoded adresses definetly not in moers
bs_15 <- bs_15[bs_15$lon>6.4984130859375 & bs_15$lon< 6.7380523681640625,]
bs_15 <- bs_15[bs_15$lat>51.35977664828087 & bs_15$lat< 51.516007082492614,]

# parse date / time to create timestamp
bs_15$time_str = bs_15$time
bs_15[nchar(bs_15$time)==3,"time_str"]<- paste0("0",bs_15[nchar(bs_15$time)==3,"time"])
bs_15$dt <- paste0(bs_15$date,"T",bs_15$time_str)
bs_15$dt <- as.POSIXct(bs_15$dt,"Europe/Zurich", "%d.%m.%YT%H%M")
bs_15$timestamp <- as.numeric(bs_15$dt)
bs_15$dt <- bs_15$time_str <- NULL

# parse bussgeld
bs_15$busse <- as.numeric(sub(",",".", sub(" \u0080", "", sub("-  ", "0", bs_15$busse))))



# write.csv(bs_15, "owi-daten-rv-2015-geocoded.csv")
# bs_15 <- read.csv("owi-daten-rv-2015-geocoded.csv")

library("rgdal")
# data(bs_15)
coordinates(bs_15) = c("lon", "lat")
class(bs_15)
# [1] "SpatialPointsDataFrame"
writeOGR(bs_15, "moersjson", layer="bussgeld", driver="GeoJSON")

# tatbestande <- unique(bs_15$tatbestand)


