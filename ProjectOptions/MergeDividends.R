library(data.table)
library(dplyr)

Sys.setenv(TZ = "US/Eastern")

setwd("/Users/yilongju/Dropbox/Study/2018_Summer/MatlabProject/Options")
spOptionDataRaw <- fread("sp500_option_prices_merged.csv")

colnames(spOptionDataRaw) <- c("secid", "startDate", "expireDate", "bidPrice", "askPrice", "volume", "impl_volatility", "delta", "gamma", "vega", "theta", "strikePrice", "startDateIdx", "expireDateIdx", "dateLen", "lowPrice", "highPrice", "openPrice", "return", "cpFlag", "closePrice")
head(spOptionData)
spOptionData <- spOptionDataRaw %>% select(startDate, expireDate, dateLen, bidPrice, askPrice, strikePrice, cpFlag, closePrice)
spOptionData$startDate <- as.character(spOptionData$startDate)
spOptionData$expireDate <- as.character(spOptionData$expireDate)
spOptionData$startDate <- as.Date(spOptionData$startDate, format = "%Y%m%d")
spOptionData$expireDate <- as.Date(spOptionData$expireDate, format = "%Y%m%d")

dividendsData <- fread("dividendsData.csv")
colnames(dividendsData) <- c("date", "dividends")
dividendsData
dividendsData$date <- as.character(dividendsData$date)
dividendsData$date <- as.Date(dividendsData$date, format = "%d-%b-%y")

# spOptionData$startDate[1]
# dividendsData$date[length(dividendsData$date)]
# spOptionData$startDate[1] < dividendsData$date[length(dividendsData$date)]

for (i in 1:nrow(spOptionData)) {
  cat(i, " / ", nrow(spOptionData), "\n")
  divid <- 0
  sttDate <- spOptionData$startDate[i]
  expirDate <- spOptionData$expireDate[i]
  
  for (j in 1:nrow(dividendsData)) {
    dividDate <- dividendsData$date[j]
    if (dividDate >= sttDate & dividDate <= expirDate) {
      divid <- divid + dividendsData$dividends[j]
    }
  }
  spOptionData$dividends <- divid
}

iList <- c(1, 2)

spOptionData179 <- spOptionData %>% filter(dateLen == 179)

GetDividendsList <- function(spOptionData, dividendsData) {
  dividendsList <- sapply(1:nrow(spOptionData), function(i) {
    cat(i, " / ", nrow(spOptionData), "\n")
    divid <- 0
    sttDate <- spOptionData$startDate[i]
    expirDate <- spOptionData$expireDate[i]
    
    dividList <- sapply(1:nrow(dividendsData), function(j) {
      dividDate <- dividendsData$date[j]
      if (dividDate >= sttDate & dividDate <= expirDate) {
        divid <- divid + dividendsData$dividends[j]
      }
    })
    # spOptionData$dividends <- divid
    return(sum(unlist(dividList)))
  })
  return(dividendsList)
}

dividendsList179 <- GetDividendsList(spOptionData179, dividendsData)
head(dividendsList179)
spOptionData179$dividends <- dividendsList179
head(spOptionData179)

write.csv(spOptionData179, "spOptionData179.csv")




