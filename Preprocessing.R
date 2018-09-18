library(data.table)
library(dplyr)
library(reshape2)
library(ggplot2)

setwd("/Users/yilongju/Dropbox/Study/2018_Summer/MatlabProject/Options/ProjectOption2")
Sys.setenv(TZ = "US/Eastern")

# [Read option data] ----
sp500_option_prices_1996_2017 <- fread("sp500_option_prices_1996_2017.csv")
head(sp500_option_prices_1996_2017)

sp500_option_prices_1996_2017$date <- as.Date(as.character(sp500_option_prices_1996_2017$date), format = "%Y%m%d")
sp500_option_prices_1996_2017$exdate <- as.Date(as.character(sp500_option_prices_1996_2017$exdate), format = "%Y%m%d")

sp500_option_prices_2002_2017 <- sp500_option_prices_1996_2017 %>% filter(date >= "2002-01-01")
head(sp500_option_prices_2002_2017)
head(sp500_option_prices_2002_2017 %>% distinct(date) %>% arrange(date), 20)

# [Read stock price data] ----
spPrice <- fread("spIndex_20122017.csv")
spPrice$date <- as.character(spPrice$date)
spPrice$date <- as.Date(spPrice$date, format = "%Y%m%d")
head(spPrice)
head(spPrice %>% distinct(date) %>% arrange(date), 20)

# [Read another stock price data] ----
spPrice_1996_2018 <- fread("spPrice_1996_2018.csv")
head(spPrice_1996_2018)
spPrice_1996_2018$Date <- as.Date(spPrice_1996_2018$Date, format = "%Y-%m-%d")

spDataCompare <- inner_join(spPrice, spPrice_1996_2018, by = c("date" = "Date"))
spDataCompare_clean <- spDataCompare %>% select(date, close, Close) %>% mutate(diff = abs(close - Close))
sum(spDataCompare_clean$diff)
# [1] 0.071889
head(spDataCompare_clean, 20)

# [Merge data] ----
spOptionDataRaw <- left_join(sp500_option_prices_1996_2017, spPrice_1996_2018, by = c("date" = "Date")) %>% rename(close = Close)
head(spOptionDataRaw)

spOptionDataRaw <- spOptionDataRaw %>% select(date, symbol, exdate, cp_flag, strike_price, best_bid, impl_volatility, close) %>% filter(date >= "2002-01-01")

# spOptionDataRaw_SPXW <- spOptionDataRaw %>% filter(substr(symbol, 1, 4) == "SPXW")
# dim(spOptionDataRaw)
# dim(spOptionDataRaw_SPXW)
# head(spOptionDataRaw_SPXW)
# 
# spOptionDataRaw2013 <- spOptionDataRaw_SPXW %>% filter(date >= "2013-01-01" & date <= "2013-12-31")
spOptionDataRaw2013 <- spOptionDataRaw
spOptionDataRaw2013 <- spOptionDataRaw2013 %>% mutate(strike_price = strike_price / 1000)
spOptionDataRaw2013 <- spOptionDataRaw2013 %>% mutate(maturity = as.numeric(exdate - date, units = "days"))
head(spOptionDataRaw2013 %>% filter(maturity == 49), 10)
spOptionDataRaw2013_distinctMaturity <- spOptionDataRaw2013 %>% select(maturity) %>% arrange(maturity) %>% distinct(maturity)
spOptionDataRaw2013 <- spOptionDataRaw2013 %>% mutate(maturityDiff = abs(maturity - 30))
spOptionDataRaw2013 <- data.frame(spOptionDataRaw2013 %>% group_by(date) %>% filter((maturityDiff == min(maturityDiff)) & (!is.na(impl_volatility))))

head(spOptionDataRaw2013 %>% distinct(date, maturity), 20)

hist(spOptionDataRaw2013$maturity)
dim(spOptionDataRaw2013)


# spOptionDataRaw2013 <- spOptionDataRaw2013 %>% filter((maturity == 30 | maturity == 31) & (!is.na(impl_volatility)))


head(spOptionDataRaw2013)
spOptionDataRaw2013

# [Find out duplicated rows ---> Need to filter out only one index] ----
head(spOptionDataRaw2013 %>% filter(date == "2017-05-16" & exdate == "2017-06-16" & strike_price >= 2075 & strike_price <= 2230 & maturity == 31) %>% arrange(strike_price, cp_flag), 20)


df <- spOptionDataRaw2013 %>% select(date, exdate, strike_price, maturity, close, cp_flag, best_bid)
duplicatedIndices <- duplicated(df) | duplicated(df, fromLast = TRUE)
length(duplicatedIndices)
head(df[duplicatedIndices, ], 20)


spOptionDataRaw2013_noVol <- spOptionDataRaw2013 %>% select(-impl_volatility)
head(spOptionDataRaw2013_noVol)

spOptionDataRaw2013_dcast_bid <- dcast(spOptionDataRaw2013, date + exdate + strike_price + maturity + close ~ cp_flag, value.var = "best_bid")
head(spOptionDataRaw2013_dcast_bid)
dim(spOptionDataRaw2013_dcast_bid %>% filter(C != 1 | P != 1))

head(spOptionDataRaw2013_dcast_bid %>% filter(C != 1 | P != 1), 20)
head(spOptionDataRaw2013_dcast_bid %>% filter(C > 1 | P > 1), 20)
dim(spOptionDataRaw2013_dcast_bid %>% filter(C > 1 | P > 1))



# [Split different indice] ----
spOptionDataRaw_SPXW <- spOptionDataRaw2013 %>% filter(substr(symbol, 1, 4) == "SPXW")
spOptionDataRaw_SPX <- spOptionDataRaw2013 %>% filter(substr(symbol, 1, 4) == "SPX ")
dim(spOptionDataRaw_SPXW)
dim(spOptionDataRaw_SPX)
dim(spOptionDataRaw2013)
dim(spOptionDataRaw_SPXW)[1] + dim(spOptionDataRaw_SPX)[1]

distinctTickers <- spOptionDataRaw2013 %>% distinct(ticker = substr(symbol, 1, 4))
dim(distinctTickers)
head(distinctTickers, 20)

spOptionDataRaw2013 %>% group_by(substr(symbol, 1, 4)) %>% distinct(strike_price, .keep_all = T) %>% summarise(count = n()) %>% arrange(desc(count))

spOptionDataRaw2013 %>% filter(substr(symbol, 1, 4) == "QSE.") %>% distinct(strike_price, .keep_all = T)


head(spOptionDataRaw2013 %>% distinct(strike_price, .keep_all = T), 20)

# dcast data ----

spOptionDataRaw2013_noVol <- spOptionDataRaw2013 %>% select(-impl_volatility)
head(spOptionDataRaw2013_noVol)

spOptionDataRaw2013_dcast_bid <- dcast(spOptionDataRaw2013, date + exdate + strike_price + maturity + close ~ cp_flag, value.var = "best_bid")
head(spOptionDataRaw2013_dcast_bid)
spOptionDataRaw2013_dcast_vol <- dcast(spOptionDataRaw2013, date + exdate + strike_price + maturity + close ~ cp_flag, value.var = "impl_volatility")
head(spOptionDataRaw2013_dcast_vol)
spOptionDataRaw2013_dcast_vol <- spOptionDataRaw2013_dcast_vol %>% rename(sigmaCall = C, sigmaPut = P)

spOptionDataRaw2013_dcast <- left_join(spOptionDataRaw2013_dcast_bid, spOptionDataRaw2013_dcast_vol, by = c("date", "exdate", "strike_price", "maturity", "close"))
head(spOptionDataRaw2013_dcast)





# [Save data for MATLAB] ----
setwd("/Users/yilongju/Dropbox/Study/2018_Summer/MatlabProject/Options/ProjectOption2/tempdata2")

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