library(sp)
library(gstat)
library(fields)
library(classInt)
library(maps)
library(xlsx)

data = read.csv("C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/dataset/Case.csv", as.is = T)
data = data[data$province == "Daegu"| data$province == "Gyeongsangbuk-do"|data$province ==  "Gyeongsangnam-do",]
data = subset(data, select=c("confirmed","latitude","longitude"))
data = as.matrix(data)
data = data[data[,2]!="-",]
data = as.data.frame(matrix(as.numeric(data), ncol=3))
colnames(data) <- c("confirmed", "lat", "lon")
data

plot.point.ref <- function(spatialdata, vals) {
  pal <- tim.colors(10)
  ints <- classIntervals(vals, n = 8, style = "pretty")
  # also see style options "quantile" and "fisher"
  intcols <- findColours(ints, pal) # vector of colors
  # if pal doesn't have the same length as # classes, findColours will interpolate
  
  par(mar = rep(3, 4))
  plot(spatialdata, col = intcols, pch = 19, add=TRUE)
  points(spatialdata, pch = 1)
  legend("right", fill = attr(intcols, "palette"),
         legend = names(attr(intcols, "table")), bty = "n")
  legend("topright", 
         legend = coef, bty = "n")
}


lin <- lm(confirmed ~ lon + lat , data = data)
coef <- paste0("<Coefficients>","\n",
               "intercept:",round(lin$coefficients[1],2),"\n",
               "longitude(beta 1):",round(lin$coefficients[2],2),"\n",
               "lattitude(beta 2):",round(lin$coefficients[3],2))

fitted <- predict(lin, newdata = data)
ehat <- data$confirmed - fitted # residuals

class(data)
sp <- SpatialPoints(coords = data[,3:2])
data_sp <- SpatialPointsDataFrame(sp, data=as.data.frame(data$confirmed))

par(mfrow=c(1,1))
x11()
plot.point.ref(data_sp, ehat)
sidoMap
map("world", region = 'South Korea', add = TRUE)
title(main = "Residual plot with OLS beta")




#### 시/도 구분
# install.packages("ggmap")
library(ggmap)
library(ggplot2)
# install.packages("rgdal")
library(rgdal)

sido <- 
  rgdal::readOGR(
    dsn = 'C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/dataset',
    layer = 'korea',
    encoding = 'CP949')

class(x=sido)
sido
sidoDf <- fortify(model = sido)
str(object = sidoDf)
sido@data
sido@data$id <- rownames(x = sido@data)

library(dplyr)
sidoDf = sidoDf %>% left_join(sido@data, by = "id")
sidoDf <- sidoDf[order(sidoDf$id, sidoDf$order), ]
head(sidoDf,3)

table(sidoDf$CTP_ENG_NM) %>% sort()


sidoDf1 <- sidoDf[sidoDf$CTP_ENG_NM == "Daegu"|sidoDf$CTP_ENG_NM == "Gyeongsangbuk-do"|sidoDf$CTP_ENG_NM == "Gyeongsangnam-do", ]
nrow(x = sidoDf1)

my_theme <- theme(panel.background = element_blank(),
                  axis.title = element_blank(),
                  axis.text = element_blank(),
                  axis.ticks = element_blank(),
                  plot.title = element_text(hjust = 0.5,
                                            face = 'bold'))

sidoMap <- 
  ggplot(data = sidoDf1,add=TRUE,
         mapping = aes(x = lat,
                       y = long,
                       group = group)) + 
  geom_polygon(fill = 'white',
               color = 'black') + 
  my_theme

# sidoMap을 그립니다. 
x11()
sidoMap

head(sidoDf1,3)
data_sp



