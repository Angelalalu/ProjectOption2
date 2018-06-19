library(ggplot2)
library(data.table)
library(dplyr)
library(reshape2)

setwd("C:/Users/Sizhu/Documents/03_2018Summer/Option/ProjectOption/")

perc_stata <- fread("sp500_percentiles_stata.csv")
perc_matlab <- fread("sp500_percentiles_matlab.csv")

perc_stata$price_date <- as.character(perc_stata$price_date)
perc_stata$price_date <- as.Date(perc_stata$price_date, format = "%d%b%Y")
head(perc_stata)
perc_stata = rename(perc_stata, p5_stata = p5, p10_stata = p10, p25_stata = p25, p50_stata = p50, p75_stata = p75, p90_stata = p90, p95_stata = p95)

perc_matlab$price_date <- as.character(perc_matlab$price_date)
perc_matlab$price_date <- as.Date(perc_matlab$price_date, format = "%d-%b-%y")
head(perc_matlab)
perc_matlab = rename(perc_matlab, p5_matlab = p5, p10_matlab = p10, p25_matlab = p25, p50_matlab = p50, p75_matlab = p75, p90_matlab = p90, p95_matlab = p95)

perc <- merge(perc_stata, perc_matlab, by="price_date")
head(perc)
perc_long <- melt(perc, id = "price_date")
head(perc_long)

my_colormap = c("pink", "orange", "yellow", "green", "cyan", "blue", "red")
ggplot(perc_long) + geom_line(aes(x=price_date, y=value, colour=variable, linetype=variable), size = 0.75) +
  scale_colour_manual(values=c(my_colormap,my_colormap)) + 
  scale_linetype_manual(values=rep(c("solid", "dashed"), each = 7)) +
  ylab("percentiles")



# 
# 
# ggplot()+
#   geom_line(data = perc_stata, aes(x = price_date, y = p5), color = "pink", size = 1)+
#   geom_line(data = perc_stata, aes(x = price_date, y = p10), color = "orange", size = 1)+
#   geom_line(data = perc_stata, aes(x = price_date, y = p25), color = "yellow", size = 1)+
#   geom_line(data = perc_stata, aes(x = price_date, y = p50), color = "green", size = 1)+
#   geom_line(data = perc_stata, aes(x = price_date, y = p75), color = "cyan", size = 1)+
#   geom_line(data = perc_stata, aes(x = price_date, y = p90), color = "blue", size = 1)+
#   geom_line(data = perc_stata, aes(x = price_date, y = p95), color = "red", size = 1)+
#   geom_line(data = perc_matlab, aes(x = price_date, y = p5), color = "pink", size = 1, linetype = 2)+
#   geom_line(data = perc_matlab, aes(x = price_date, y = p10), color = "orange", size = 1, linetype = 2)+
#   geom_line(data = perc_matlab, aes(x = price_date, y = p25), color = "yellow", size = 1, linetype = 2)+
#   geom_line(data = perc_matlab, aes(x = price_date, y = p50), color = "green", size = 1, linetype = 2)+
#   geom_line(data = perc_matlab, aes(x = price_date, y = p75), color = "cyan", size = 1, linetype = 2)+
#   geom_line(data = perc_matlab, aes(x = price_date, y = p90), color = "blue", size = 1, linetype = 2)+
#   geom_line(data = perc_matlab, aes(x = price_date, y = p95), color = "red", size = 1, linetype = 2)+
#   ylab("percentiles")+
#   scale_color_discrete(name = "sp500 percentiles", labels = c("5th percentile - stata",
#                       "10th percentile - stata","25th percentile - stata","50th percentile - stata",
#                       "75th percentile - stata","90th percentile - stata","95th percentile - stata",
#                       "5th percentile - matlab","10th percentile - matlab","25th percentile - matlab",
#                       "50th percentile - matlab","75th percentile - matlab","90th percentile - matlab",
#                       "95th percentile - matlab"))
