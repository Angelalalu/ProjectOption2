library(data.table)
library(dplyr)
library(reshape2)

Sys.setenv(TZ = "US/Eastern")

setwd("C:/Users/Sizhu/Documents/03_2018Summer/Option/ProjectOption/")
spOptionDataRaw <- fread("sp500_option_prices.csv")
spPrice <- fread("spIndex_20122017.csv")

head(spOptionDataRaw)
head(spPrice)
spPrice$date <- as.character(spPrice$date)
spPrice$date <- as.Date(spPrice$date, format = "%Y%m%d")

spOptionDataRaw$date <- as.character(spOptionDataRaw$date)
spOptionDataRaw$date <- as.Date(spOptionDataRaw$date, format = "%Y%m%d")
spOptionDataRaw$exdate <- as.character(spOptionDataRaw$exdate)
spOptionDataRaw$exdate <- as.Date(spOptionDataRaw$exdate, format = "%Y%m%d")

spOptionDataRaw <- left_join(spOptionDataRaw, spPrice, by = "date")
spOptionDataRaw <- spOptionDataRaw %>% select(date, symbol, exdate, cp_flag, strike_price, best_bid, impl_volatility, close)

spOptionDataRaw_SPXW <- spOptionDataRaw %>% filter(substr(symbol, 1, 4) == "SPXW")
dim(spOptionDataRaw)
dim(spOptionDataRaw_SPXW)
head(spOptionDataRaw_SPXW)

spOptionDataRaw2013 <- spOptionDataRaw_SPXW %>% filter(date >= "2013-01-01" & date <= "2013-12-31")
spOptionDataRaw2013 <- spOptionDataRaw2013 %>% mutate(strike_price = strike_price / 1000)
spOptionDataRaw2013 <- spOptionDataRaw2013 %>% mutate(maturity = as.numeric(exdate - date, units = "days"))
# spOptionDataRaw2013 %>% filter(maturity == 49)
spOptionDataRaw2013_distinctMaturity <- spOptionDataRaw2013 %>% select(maturity) %>% arrange(maturity) %>% distinct(maturity)
spOptionDataRaw2013 <- spOptionDataRaw2013 %>% mutate(maturityDiff = abs(maturity - 30))
spOptionDataRaw2013 <- data.frame(spOptionDataRaw2013 %>% group_by(date) %>% filter((maturityDiff == min(maturityDiff)) & (!is.na(impl_volatility))))

spOptionDataRaw2013 %>% distinct(date, maturity)

hist(spOptionDataRaw2013$maturity)
dim(spOptionDataRaw2013)


# spOptionDataRaw2013 <- spOptionDataRaw2013 %>% filter((maturity == 30 | maturity == 31) & (!is.na(impl_volatility)))

head(spOptionDataRaw2013)

spOptionDataRaw2013_noVol <- spOptionDataRaw2013 %>% select(-impl_volatility)
head(spOptionDataRaw2013_noVol)

spOptionDataRaw2013_dcast_bid <- dcast(spOptionDataRaw2013, date + exdate + strike_price + maturity + close ~ cp_flag, value.var = "best_bid")
head(spOptionDataRaw2013_dcast_bid)
spOptionDataRaw2013_dcast_vol <- dcast(spOptionDataRaw2013, date + exdate + strike_price + maturity + close ~ cp_flag, value.var = "impl_volatility")
head(spOptionDataRaw2013_dcast_vol)
spOptionDataRaw2013_dcast_vol <- spOptionDataRaw2013_dcast_vol %>% rename(sigmaCall = C, sigmaPut = P)

spOptionDataRaw2013_dcast <- left_join(spOptionDataRaw2013_dcast_bid, spOptionDataRaw2013_dcast_vol, by = c("date", "exdate", "strike_price", "maturity", "close"))
head(spOptionDataRaw2013_dcast)

setwd("C:/Users/Sizhu/Documents/03_2018Summer/Option/ProjectOption/tempdata")
SaveDataForMATLAB <- function(data, speDate) {
  speDateStr <- speDate
  speDate <- as.Date(speDate, format = "%Y%m%d")
  data <- data %>% filter(date == speDate)
  dim(data)
  data <- data %>% rename(K = strike_price, T = maturity, S = close)
  data <- data %>% select(-date, -exdate) %>% mutate(rf = 0.005)
  data <- data %>% filter(complete.cases(data))
  data <- data %>% mutate(T = T / 365)
  data <- data %>% select(K, C, P, T, rf, S, sigmaCall, sigmaPut)
  write.table(data, paste0("data", speDateStr, ".txt"),
              quote = F, sep = ",", row.names = F, qmethod = "escape")
}
# SaveDataForMATLAB(spOptionDataRaw2013_dcast, "2013-01-02")

dateList2013 <- spOptionDataRaw2013_dcast %>% distinct(date) %>% arrange(date)
dateList2013 <- as.character(as.Date(dateList2013$date, format = "%Y%m%d"))
dateList2013 <- gsub("-", "", dateList2013, fixed = T)

for (date in dateList2013) {
  SaveDataForMATLAB(spOptionDataRaw2013_dcast, date)
}


# 
# spOptionDataRaw2013_dcast <- spOptionDataRaw2013_dcast %>% filter(date == "2013-01-02")
# spOptionDataRaw2013_dcast <- spOptionDataRaw2013_dcast %>% rename(K = strike_price, T = maturity, S = close)
# spOptionDataRaw2013_dcast <- spOptionDataRaw2013_dcast %>% select(-date, -exdate) %>% mutate(rf = 0.005)
# 
# dim(spOptionDataRaw2013_dcast)
# spOptionDataRaw2013_dcast <- spOptionDataRaw2013_dcast %>% filter(complete.cases(spOptionDataRaw2013_dcast))
# spOptionDataRaw2013_dcast <- spOptionDataRaw2013_dcast %>% mutate(T = T / 365)
# spOptionDataRaw2013_dcast <- spOptionDataRaw2013_dcast %>% select(K, C, P, T, rf, S, sigmaCall, sigmaPut)
# head(spOptionDataRaw2013_dcast)
# 
# setwd("/Users/yilongju/Dropbox/Study/2018_Summer/MatlabProject/Options/ProjectOption2/tempdata")
# write.table(spOptionDataRaw2013_dcast, "spOptionDataRaw2013_dcast.txt", quote = F, sep = ",", row.names = F, qmethod = "escape")
# 
# 
# 
# 
# 
# sum(is.na(spOptionDataRaw2013$impl_volatility)) / length(spOptionDataRaw2013$impl_volatility)
# sum(is.na(spOptionDataRaw2013$impl_volatility)) / length(spOptionDataRaw2013$impl_volatility)
# spOptionDataRaw2013 %>% filter(date == "2013-01-02" & exdate == "2013-02-01" & strike_price == 1100)
# head(spOptionDataRaw2013)
# spOptionDataRaw2013 %>% filter(strike_price == 1225, maturity == 30, close == 1462.42)
# 
# 
# names(airquality) <- tolower(names(airquality))
# head(airquality, 20)
# meltAQ <- melt(airquality, id=c("month", "day"))
# head(meltAQ, 20)
# 
# names(airquality) <- tolower(names(airquality))
# aqm <- melt(airquality, id=c("month", "day"), na.rm=TRUE)
# acast(aqm, day ~ month ~ variable)
# dcast(aqm, month + day ~ variable)
# head(aqm, 20)
