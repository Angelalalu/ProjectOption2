library(data.table)
library(dplyr)
Sys.setenv(TZ = "US/Eastern")
setwd("C:/Users/Sizhu/Documents/03_2018Summer/Option/ProjectOption")
setwd("/Users/yilongju/Dropbox/Study/2018_Summer/MatlabProject/Options/ProjectOption2")

OptionData <- fread("1996_1998options.csv")
DividendData <- fread("1996_1998dividend.csv")
IndexData <- fread("1996_1998indexlevel.csv")

head(OptionData)
OptionData <- OptionData %>% select(-secid)
OptionData$date <- as.character(OptionData$date)
OptionData$exdate <- as.character(OptionData$exdate)
OptionData$date <- as.Date(OptionData$date, format = "%Y%m%d")
OptionData$exdate <- as.Date(OptionData$exdate, format = "%Y%m%d")
OptionData$cp_flag[OptionData$cp_flag == "C"] <- 0
OptionData$cp_flag[OptionData$cp_flag == "P"] <- 1

head(DividendData)
colnames(DividendData) <- c("date","dividends")
DividendData$date <- as.character(DividendData$date)
DividendData$date <- as.Date(DividendData$date, format = "%m/%d/%Y")
DividendData <- DividendData %>% arrange(date)

head(IndexData)
IndexData <- IndexData %>% select(Date, Close)
colnames(IndexData) <- c("date","price")
IndexData$date <- as.character(IndexData$date)
IndexData$date <- as.Date(IndexData$date, format = "%Y-%m-%d")

OptionMerged <- left_join(OptionData, IndexData, by = "date")
OptionMerged$strike_price <- OptionMerged$strike_price / 1000
head(OptionMerged)
write.csv(OptionMerged,"1996_1998OptionMerged.csv", row.names = F)

### Merge Dividends
AddDividendsListToData <- function(spOptionData, dividendsData) {
  spOptionData_t <- spOptionData
  originColNum <- ncol(spOptionData)
  for (i in 1:nrow(dividendsData)) {
    cat(i, " / ", nrow(dividendsData), "\n")
    dividendList_i <- ((spOptionData$date <= dividendsData$date[i])
                       & (spOptionData$exdate >= dividendsData$date[i])) * dividendsData$dividends[i]
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

OptionDataWDiv <- AddDividendsListToData(OptionMerged, DividendData)
OptionDataWDiv$cp_flag <- as.integer(OptionDataWDiv$cp_flag)
head(OptionDataWDiv)
OptionDataWDiv$dateLen <- OptionDataWDiv$exdate - OptionDataWDiv$date
OptionDataWDiv$dateLen <- as.integer(OptionDataWDiv$dateLen)
write.csv(OptionDataWDiv,"1996_1998OptionDataWDiv.csv", row.names = F)

### Separate Date
SeparateDate <- function(data) {
  data$startYear <- as.numeric(substr(data$date, 1, 4))
  data$startMonth <- as.numeric(substr(data$date, 6, 7))
  data$startDay <- as.numeric(substr(data$date, 9, 10))
  data$expireYear <- as.numeric(substr(data$exdate, 1, 4))
  data$expireMonth <- as.numeric(substr(data$exdate, 6, 7))
  data$expireDay <- as.numeric(substr(data$exdate, 9, 10))
  data <- data %>% select(-date, -exdate)
}
OptionDataWDiv <- SeparateDate(OptionDataWDiv)


### Calculate d & r
# Calculate APR
OptionDataWDiv <- OptionDataWDiv %>% mutate(annlPayoutReturn = (1 + dividends/price)^(1/(dateLen/365)))
OptionDataCheckNAN <- OptionDataWDiv[!complete.cases(OptionDataWDiv),]
head(OptionDataCheckNAN)


# Calculate interest rates
CalculateBorrowInterestRate <- function(bid, ask, cpFlag, APR, close, t, strike) {
  return(((mean(bid[cpFlag == 1]) + close*APR^(-t/365) - mean(ask[cpFlag == 0]))/strike)^(-365/t))
}
CalculateLendInterestRate <- function(bid, ask, cpFlag, APR, close, t, strike) {
  return(((mean(ask[cpFlag == 1]) + close*APR^(-t/365) - mean(bid[cpFlag == 0]))/strike)^(-365/t))
}

OptionDataWDiv <- data.frame(OptionDataWDiv %>% 
                               group_by(dateLen, strike_price, startYear, startMonth, startDay) %>% 
                               mutate(
                                 borrowInterestRate = CalculateBorrowInterestRate(
                                   best_bid, best_offer, cp_flag, annlPayoutReturn,
                                   price, dateLen, strike_price),
                                 lendInterestRate = CalculateLendInterestRate(
                                   best_bid, best_offer, cp_flag, annlPayoutReturn,
                                   price, dateLen, strike_price)))
# head(OptionDataWDiv)
# OptionDataCheckNAN <- OptionDataWDiv[!complete.cases(OptionDataWDiv),]
# OptionDataCheckNAN <- data.frame(OptionDataCheckNAN %>% 
#   group_by(dateLen, strike_price, startYear, startMonth, startDay) %>% 
#   mutate(
#     borrowInterestRate = CalculateBorrowInterestRate(
#       best_bid, best_offer, cp_flag, annlPayoutReturn,
#       price, dateLen, strike_price)))
# 
# dim(OptionDataCheckNAN)
# length(OptionDataCheckNAN$best_bid[OptionDataCheckNAN$cp_flag == 1])
# length(OptionDataCheckNAN$best_bid[OptionDataCheckNAN$cp_flag == 0])
# head(OptionDataCheckNAN %>% arrange(dateLen, strike_price, startYear, startMonth, startDay))

OptionDataWDiv <- OptionDataWDiv[complete.cases(OptionDataWDiv),]
OptionDataWDiv <- data.frame(OptionDataWDiv %>% 
                                 group_by(dateLen, startYear, startMonth, startDay) %>% 
                                 mutate(borrowInterestRate = median(borrowInterestRate),
                                        lendInterestRate = median(lendInterestRate)))



head(OptionDataWDiv, 10)

### Select 1996_179 Options
OptionDataWDiv1996_179 <- OptionDataWDiv %>% filter(startYear == 1996, startMonth == 6, startDay == 25, dateLen == 179)
head(OptionDataWDiv1996_179)
range(OptionDataWDiv1996_179$price)


write.csv(OptionDataWDiv1996_179, "OptionDataWDiv1996_179.csv", row.names = F)


