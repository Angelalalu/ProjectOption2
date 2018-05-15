library(data.table)
library(dplyr)

Sys.setenv(TZ = "US/Eastern")

setwd("~/refm-lab/users/sizhu_lu")
spOptionDataRaw <- fread("sp500_option_prices_merged.csv")

colnames(spOptionDataRaw) <- c("secid", "startDate", "expireDate", "bidPrice", "askPrice", "volume", "impl_volatility", "delta", "gamma", "vega", "theta", "strikePrice", "startDateIdx", "expireDateIdx", "dateLen", "lowPrice", "highPrice", "openPrice", "return", "cpFlag", "closePrice")
# head(spOptionDataRaw)
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

# # Calculate Dividend
# for (i in 1:nrow(spOptionData)) {
#   cat(i, " / ", nrow(spOptionData), "\n")
#   divid <- 0
#   sttDate <- spOptionData$startDate[i]
#   expirDate <- spOptionData$expireDate[i]
#   
#   for (j in 1:nrow(dividendsData)) {
#     dividDate <- dividendsData$date[j]
#     if (dividDate >= sttDate & dividDate <= expirDate) {
#       divid <- divid + dividendsData$dividends[j]
#     }
#   }
#   spOptionData$dividends <- divid
# }
# 
# iList <- c(1, 2)
# 


# GetDividendsList <- function(spOptionData, dividendsData) {
#   dividendsList <- sapply(1:nrow(spOptionData), function(i) {
#     cat(i, " / ", nrow(spOptionData), "\n")
#     divid <- 0
#     sttDate <- spOptionData$startDate[i]
#     expirDate <- spOptionData$expireDate[i]
#     
#     dividList <- sapply(1:nrow(dividendsData), function(j) {
#       dividDate <- dividendsData$date[j]
#       if (dividDate >= sttDate & dividDate <= expirDate) {
#         return(dividendsData$dividends[j])
#       }
#       return(0)
#     })
#     # spOptionData$dividends <- divid
#     return(sum(unlist(dividList)))
#   })
#   return(dividendsList)
# }

AddDividendsListToData <- function(spOptionData, dividendsData) {
  spOptionData_t <- spOptionData
  originColNum <- ncol(spOptionData)
  for (i in 1:nrow(dividendsData)) {
    cat(i, " / ", nrow(dividendsData), "\n")
    dividendList_i <- ((spOptionData$startDate <= dividendsData$date[i])
                       & (spOptionData$expireDate >= dividendsData$date[i])) * dividendsData$dividends[i]
    spOptionData_t <- cbind(spOptionData_t, dividendList_i)
  }
  newColNum <- ncol(spOptionData_t)
  newColNames <- colnames(spOptionData_t)
  newColNames[(originColNum+1):newColNum] <- paste0("dividend_", 1:nrow(dividendsData))
  newColNames[newColNum] <- "dividend_last"
  colnames(spOptionData_t) <- newColNames
  dividendsMatrix <- spOptionData_t %>% select(dividend_1:dividend_last)
  dividendsList <- rowSums(dividendsMatrix, na.rm = TRUE)
  spOptionData_t2 <- spOptionData
  spOptionData_t2$dividends <- dividendsList
  return(spOptionData_t2)
}

CalculateBorrowInterestRate <- function(bid, ask, cpFlag, APR, close, t, strike) {
  return(((mean(bid[cpFlag == 1]) + close*APR^(-t/365) - mean(ask[cpFlag == 0]))/strike)^(-365/t))
}
CalculateLendInterestRate <- function(bid, ask, cpFlag, APR, close, t, strike) {
  return(((mean(ask[cpFlag == 1]) + close*APR^(-t/365) - mean(bid[cpFlag == 0]))/strike)^(-365/t))
}

SeparateDate <- function(data) {
  data$startYear <- as.numeric(substr(data$startDate, 1, 4))
  data$startMonth <- as.numeric(substr(data$startDate, 6, 7))
  data$startDay <- as.numeric(substr(data$startDate, 9, 10))
  data$expireYear <- as.numeric(substr(data$expireDate, 1, 4))
  data$expireMonth <- as.numeric(substr(data$expireDate, 6, 7))
  data$expireDay <- as.numeric(substr(data$expireDate, 9, 10))
  data <- data %>% select(-startDate, -expireDate)
}

# ((0+2124.20*1.020728^(-179/365)-2004.40)/100)^(-365/179)

### 179 ----
spOptionData179 <- spOptionData %>% filter(dateLen == 179)
### Calculate dividends
# dividendsList179 <- GetDividendsList(spOptionData179, dividendsData)
head(dividendsList179)
spOptionData179$dividends <- dividendsList179
### Calculate APR
spOptionData179 <- spOptionData179 %>% mutate(annlPayoutReturn = (1 + dividends/closePrice)^(1/(dateLen/365)))
spOptionData179 <- SeparateDate(spOptionData179)

spOptionData179_checkGroupSize <- spOptionData179 %>% 
  group_by(dateLen, strikePrice, startYear, startMonth, startDay) %>% 
  summarise(count = n()) %>%
  filter(count == 4)

### Take average for groups with size 4
spOptionData179_bidaskAvg <- spOptionData179 %>% 
  group_by(dateLen, strikePrice, cpFlag, closePrice, dividends, annlPayoutReturn, startYear, startMonth, startDay, expireYear, expireMonth, expireDay) %>% 
  summarise(bidPrice = mean(bidPrice), askPrice = mean(askPrice))

spOptionData179_bidaskAvg <- data.frame(spOptionData179_bidaskAvg)
head(spOptionData179_bidaskAvg)

spOptionData179_bidaskAvg <- cbind(spOptionData179_bidaskAvg %>% select(dateLen), spOptionData179_bidaskAvg %>% select(bidPrice, askPrice), spOptionData179_bidaskAvg %>% select(strikePrice:expireDay))

spOptionData179_bidaskAvg_checkGroupSize <- spOptionData179_bidaskAvg %>% 
  group_by(dateLen, strikePrice, startYear, startMonth, startDay) %>% 
  summarise(count = n())

spOptionData179_bidaskAvg %>% filter(startYear == 2017, startMonth == 6, startDay == 19, strikePrice == 100)
spOptionData179 %>% filter(startYear == 2017, startMonth == 6, startDay == 19, strikePrice == 100)


### Calculate interest rates
spOptionData179 <- data.frame(spOptionData179 %>% 
  group_by(dateLen, strikePrice, startYear, startMonth, startDay) %>% 
  mutate(borrowInterestRate = CalculateBorrowInterestRate(
    bidPrice, askPrice, cpFlag, annlPayoutReturn, closePrice, dateLen, strikePrice)))

spOptionData179 <- data.frame(spOptionData179 %>% 
  group_by(dateLen, strikePrice, startYear, startMonth, startDay) %>% 
  mutate(lendInterestRate = CalculateLendInterestRate(
    bidPrice, askPrice, cpFlag, annlPayoutReturn, closePrice, dateLen, strikePrice)))

### Take median
spOptionData179 <- data.frame(spOptionData179 %>% 
  group_by(dateLen, startYear, startMonth, startDay) %>% 
  mutate(borrowInterestRate = median(borrowInterestRate),
         lendInterestRate = median(lendInterestRate)))

spOptionData179 %>% filter(startYear == 2017, startMonth == 6, startDay == 19) %>% select(borrowInterestRate) %>% arrange(borrowInterestRate)
# 184           1.020000
# 185           1.020052
spOptionData179 %>% filter(startYear == 2017, startMonth == 6, startDay == 19) %>% select(lendInterestRate) %>% arrange(lendInterestRate)
# 184        1.0101551
# 185        1.0102481

spOptionData179 <- data.frame(spOptionData179 %>% 
  mutate(interestRate = (borrowInterestRate + lendInterestRate) / 2))



# ((0+2124.20*1.020728^(-179/365)-2004.40)/100)^(-365/179)
head(spOptionData179)
head(spOptionData179, 2)
spOptionData179_checkCP <- spOptionData179 %>% arrange(strikePrice)
head(spOptionData179_checkCP, 4)

write.csv(spOptionData179, "spOptionData179.csv", row.names = F)



### ----


### Calculate Dividends for all expiration length
spOptionDataWDiv <- AddDividendsListToData(spOptionData,dividendsData)
### Calculate APR
spOptionDataWDiv <- spOptionDataWDiv %>% mutate(annlPayoutReturn = (1 + dividends/closePrice)^(1/(dateLen/365)))
spOptionDataWDiv <- SeparateDate(spOptionDataWDiv)

spOptionDataWDiv_checkGroupSize <- spOptionDataWDiv %>% 
  group_by(dateLen, strikePrice, startYear, startMonth, startDay) %>% 
  summarise(count = n()) %>%
  filter(count == 4)

### Take average for groups with size 4
spOptionDataWDiv_bidaskAvg <- spOptionDataWDiv %>% 
  group_by(dateLen, strikePrice, cpFlag, closePrice, dividends, annlPayoutReturn, startYear, startMonth, startDay, expireYear, expireMonth, expireDay) %>% 
  summarise(bidPrice = mean(bidPrice), askPrice = mean(askPrice))

spOptionDataWDiv_bidaskAvg <- data.frame(spOptionDataWDiv_bidaskAvg)
head(spOptionDataWDiv_bidaskAvg)

spOptionDataWDiv_bidaskAvg <- cbind(spOptionDataWDiv_bidaskAvg %>% select(dateLen), spOptionDataWDiv_bidaskAvg %>% select(bidPrice, askPrice), spOptionDataWDiv_bidaskAvg %>% select(strikePrice:expireDay))

spOptionDataWDiv_bidaskAvg_checkGroupSize <- spOptionDataWDiv_bidaskAvg %>% 
  group_by(dateLen, strikePrice, startYear, startMonth, startDay) %>% 
  summarise(count = n())

# spOptionDataWDiv_bidaskAvg %>% filter(startYear == 2017, startMonth == 6, startDay == 19, strikePrice == 100)
# spOptionDataWDiv %>% filter(startYear == 2017, startMonth == 6, startDay == 19, strikePrice == 100)


### Calculate interest rates
spOptionDataWDiv <- data.frame(spOptionDataWDiv %>% 
                                group_by(dateLen, strikePrice, startYear, startMonth, startDay) %>% 
                                mutate(borrowInterestRate = CalculateBorrowInterestRate(
                                  bidPrice, askPrice, cpFlag, annlPayoutReturn, closePrice, dateLen, strikePrice)))

spOptionDataWDiv <- data.frame(spOptionDataWDiv %>% 
                                group_by(dateLen, strikePrice, startYear, startMonth, startDay) %>% 
                                mutate(lendInterestRate = CalculateLendInterestRate(
                                  bidPrice, askPrice, cpFlag, annlPayoutReturn, closePrice, dateLen, strikePrice)))

### Take median
spOptionDataWDiv <- data.frame(spOptionDataWDiv %>% 
                                group_by(dateLen, startYear, startMonth, startDay) %>% 
                                mutate(borrowInterestRate = median(borrowInterestRate),
                                       lendInterestRate = median(lendInterestRate)))

spOptionDataWDiv %>% filter(startYear == 2017, startMonth == 6, startDay == 19) %>% select(borrowInterestRate) %>% arrange(borrowInterestRate)
# 184           1.020000
# 185           1.020052
spOptionDataWDiv %>% filter(startYear == 2017, startMonth == 6, startDay == 19) %>% select(lendInterestRate) %>% arrange(lendInterestRate)
# 184        1.0101551
# 185        1.0102481

spOptionDataWDiv <- data.frame(spOptionDataWDiv %>% 
                                mutate(interestRate = (borrowInterestRate + lendInterestRate) / 2))



# ((0+2124.20*1.020728^(-179/365)-2004.40)/100)^(-365/179)
head(spOptionDataWDiv)
head(spOptionDataWDiv, 2)
spOptionDataWDiv_checkCP <- spOptionDataWDiv %>% arrange(strikePrice)
head(spOptionDataWDiv_checkCP, 4)

write.csv(spOptionDataWDiv, "spOptionDataWDiv.csv", row.names = F)


