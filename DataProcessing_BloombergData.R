library(data.table)
library(dplyr)
Sys.setenv(TZ = "US/Eastern")
setwd("C:/Users/Sizhu/Documents/03_2018Summer/Option/ProjectOption")

OptionData <- fread("spOptions_Bloomberg.csv")
head(OptionData)

# Date Format
OptionData <- OptionData %>% select(price_date, mat_date, strike_price, bid)
OptionData$price_date <- as.character(OptionData$price_date)
OptionData$mat_date <- as.character(OptionData$mat_date)
OptionData$price_date <- as.Date(OptionData$price_date, format = "%m/%d/%Y")
OptionData$mat_date <- as.Date(OptionData$mat_date, format = "%m/%d/%Y")
OptionData <- OptionData %>% arrange(price_date, strike_price)
OptionData$date_len <- OptionData$mat_date - OptionData$price_date
OptionData$date_len <- as.integer(OptionData$date_len)
write.csv(OptionData,"spOptions_Bloomberg_Date.csv", row.names = F)

# Seperate Date
SeparateDate <- function(data) {
  data$st_y <- as.numeric(substr(data$price_date, 1, 4))
  data$st_m <- as.numeric(substr(data$price_date, 6, 7))
  data$st_d <- as.numeric(substr(data$price_date, 9, 10))
  data$ex_y <- as.numeric(substr(data$mat_date, 1, 4))
  data$ex_m <- as.numeric(substr(data$mat_date, 6, 7))
  data$ex_d <- as.numeric(substr(data$mat_date, 9, 10))
  data <- data %>% select(-price_date, -mat_date)
}
OptionData <- SeparateDate(OptionData)
OptionData <- OptionData %>% select(-date_len, -ex_y, -ex_m, -ex_d)
write.csv(OptionData,"spOptions_Bloomberg_SeparateDate.csv", row.names = F)

# Select 02/06/2018
OptionData_02062018 <- OptionData %>% filter(st_y == 2018, st_m == 2, st_d == 6)
write.csv(OptionData_02062018,"spOptions_Bloomberg_02062018.csv", row.names = F)
