library(sp)
library(gstat)
library(fields)
library(classInt)
library(maps)
library(dplyr)

data = read.csv("C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/dataset/Case.csv", as.is = T)
# data = data[data$province == "Daegu"| data$province == "Gyeongsangbuk-do"|data$province ==  "Gyeongsangnam-do",]
data = subset(data, select=c("province","confirmed","latitude","longitude"))
data = data[data[,3]!="-",]
data$confirmed = as.numeric(data$confirmed)
data$latitude = as.numeric(data$latitude)
data$longitude = as.numeric(data$longitude)
head(data)

patient = read.csv("C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/dataset/PatientInfo.csv", as.is = T)
# patient = patient[patient$province == "Daegu"| patient$province == "Gyeongsangbuk-do"|patient$province ==  "Gyeongsangnam-do",]
patient = subset(patient, select=c("patient_id","province","city"))
patient = patient[patient[,3]!="",]
patient = patient %>% count(city)
head(patient)

lin <- lm(confirmed ~ lon + lat , data = data)
lin$coefficients
fitted <- predict(lin, newdata = data)
ehat <- data$confirmed - fitted # residuals

class(data)
sp <- SpatialPoints(coords = data[,3:2])
data_sp <- SpatialPointsDataFrame(sp, data=as.data.frame(data$confirmed))

plot.point.ref <- function(spatialdata, vals) {
  pal <- tim.colors(10)
  ints <- classIntervals(vals, n = 8, style = "pretty")
  # also see style options "quantile" and "fisher"
  intcols <- findColours(ints, pal) # vector of colors
  # if pal doesn't have the same length as # classes, findColours will interpolate
  
  par(mar = rep(3, 4))
  plot(spatialdata, col = intcols, pch = 19)
  points(spatialdata, pch = 1)
  legend("right", fill = attr(intcols, "palette"),
         legend = names(attr(intcols, "table")), bty = "n")
}

par(mfrow=c(1,1))
plot.point.ref(data_sp, ehat)
title(main = "Residual plot with OLS beta")



# install.packages("ggmap")
library(ggmap)
library(ggplot2)
# install.packages("rgdal")
library(rgdal)

sigungu <- 
  rgdal::readOGR(
    dsn = 'C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/sigungu',
    layer = 'sigungu',
    encoding = 'CP949')

sido <- 
  rgdal::readOGR(
    dsn = 'C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/dataset',
    layer = 'korea',
    encoding = 'CP949')

total <- 
  rgdal::readOGR(
    dsn = 'C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/total',
    layer = 'total',
    encoding = 'CP949')

###########################################################

sigunguDf <- fortify(model = sigungu)
sidoDf <- fortify(model = sido)
totalDf <- fortify(model = total)
nrow(totalDf)
nrow(sigunguDf)
nrow(sidoDf)
head(totalDf)

str(object = sigunguDf)
str(object = sidoDf)
str(object = totalDf)

sigungu@data$id <- rownames(x = sigungu@data)
sido@data$id <- rownames(x = sido@data)
total@data$id <- rownames(x = total@data)

###########################################################

library(dplyr)
sigunguDf = sigunguDf %>% left_join(sigungu@data, by = "id")
sigunguDf <- sigunguDf[order(sigunguDf$id, sigunguDf$order), ]
head(sigunguDf,3)

sidoDf = sidoDf %>% left_join(sido@data, by = "id")
sidoDf <- sidoDf[order(sidoDf$id, sidoDf$order), ]
head(sidoDf,3)
table(sidoDf$CTP_ENG_NM) %>% sort()
sidoDf1 <- sidoDf[sidoDf$CTP_ENG_NM == "Daegu"|sidoDf$CTP_ENG_NM == "Gyeongsangbuk-do"|sidoDf$CTP_ENG_NM == "Gyeongsangnam-do", ]
nrow(x = sidoDf1)

totalDf = totalDf %>% left_join(total@data, by = "id")
totalDf <- totalDf[order(totalDf$id, totalDf$order), ]
head(totalDf,3)
head(totalDf,3)
table(totalDf$CTP_ENG_NM) %>% sort()

totalDf1 <- totalDf[totalDf$CTP_ENG_NM == "Daegu"|totalDf$CTP_ENG_NM == "Gyeongsangbuk-do"|totalDf$CTP_ENG_NM == "Gyeongsangnam-do", ]
nrow(x = totalDf1)
head(totalDf1,3)

###########################################################
head(sigunguDf)
head(patient)

mode(sigunguDf$city)
mode(patient$city)
sigunguDf$city = as.character(sigunguDf$city)

a = patient %>% left_join(sigunguDf[c(1:2,8)], by = "city")
nrow(patient);nrow(a)
head(a)

sigunguDf[sigunguDf$city == "Andong-si",]
###########################################################


my_theme <- theme(panel.background = element_blank(),
                  axis.title = element_blank(),
                  axis.text = element_blank(),
                  axis.ticks = element_blank(),
                  plot.title = element_text("confirmed",hjust = 0.5,
                                            face = 'bold'))

# totalMap <- 
#   ggplot(data = totalDf1,add=TRUE,
#          mapping = aes(x = long,
#                        y = lat,
#                        group = group,
#                        color=data$confirmed)) + 
#   geom_polygon(fill = 'white',
#                color = 'black') +
#   my_theme +
#   geom_point(data = data,
#              mapping = aes(x = lon,
#                            y = lat,
#                            group = confirmed)) +
#   scale_color_gradient(low="blue", high="red")
# 
# x11()
# totalMap
# head(totalDf1)
# 
# sidoMap <-
#   ggplot(data = sidoDf1,add=TRUE,
#          mapping = aes(x = long,
#                        y = lat,
#                        group = group,
#                        color=data$confirmed)) +
#   geom_polygon(fill = 'white',
#                color = 'black') +
#   my_theme +
#   geom_point(data = data,
#              mapping = aes(x = lon,
#                            y = lat,
#                            group = confirmed)) +
#   scale_color_gradient(low="blue", high="red")
# 
# x11()
# sidoMap


head(sigunguDf)
head(data)
head(patient)
mode(data$latitude)
nrow(sigunguDf)

sigunguDf = sigunguDf %>% left_join(patient, by=c("city"))

#### point 찍기
sigunguMap <-
  ggplot(data = sigunguDf,add=TRUE,
         mapping = aes(x = long,
                       y = lat,
                       group = group,
                       color=data$confirmed)) +
  geom_polygon(fill = sigunguDf$n,
               color = 'black') +
  my_theme +
  geom_point(data = data[2:4],
             mapping = aes(x = longitude,
                           y = latitude,
                           group = confirmed)) +
  scale_color_gradient(low="blue", high="red") 
x11()
sigunguMap


########## 지역별 그래디언트 주기
colorbar_range <- range(sigunguDf$n)
mean_price <- mean(colorbar_range)
sigunguMap <- ggplot(data=sigunguDf) + # data layer
  geom_polygon(aes(x=long, y=lat, group=group, fill=n)) +
  scale_fill_gradient2(low='gold',mid = "white",high='firebrick2',na.value = "white",limits=colorbar_range, name='Confirmed') 


x11()
sigunguMap




######### 위경도 찾기용
head(sidoDf,3)
summary(sidoDf[,1:2])

head(sigunguDf,3)
summary(sigunguDf[,1:2])

a = sigunguDf[sigunguDf$long >= 127.6 & sigunguDf$long <= 131.8
              & sigunguDf$lat >= 34.50& sigunguDf$lat <= 37.56,]
a[1,]
b=sidoDf[sidoDf$CTP_ENG_NM == "Gyeonggi-do",]
b[1,]


