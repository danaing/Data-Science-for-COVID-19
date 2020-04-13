rm(list=ls())

library(sp)
library(gstat)
library(fields)
library(classInt)
library(maps)
library(dplyr)

data = read.csv("C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/dataset/Case.csv", as.is = T)
data = data[data$province == "Daegu"| data$province == "Gyeongsangbuk-do"|data$province ==  "Gyeongsangnam-do",]
data = subset(data, select=c("province","confirmed","latitude","longitude","city"))
data = data[data[,3]!="-",]
data$confirmed = as.numeric(data$confirmed)
data$latitude = as.numeric(data$latitude)
data$longitude = as.numeric(data$longitude)
head(data)

patient = read.csv("C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/dataset/PatientInfo.csv", as.is = T)
patient = patient[patient$province == "Daegu"| patient$province == "Gyeongsangbuk-do"|patient$province ==  "Gyeongsangnam-do",]
patient = subset(patient, select=c("patient_id","province","city"))
patient = patient[patient[,3]!="",]
head(patient)


library(ggmap)
library(ggplot2)
library(rgdal)

total <- 
  rgdal::readOGR(
    dsn = 'C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/total',
    layer = 'total',
    encoding = 'CP949')

###########################################################


totalDf <- fortify(model = total)
nrow(totalDf)

total@data$id <- rownames(x = total@data)

###########################################################

library(dplyr)
totalDf = totalDf %>% left_join(total@data, by = "id")
totalDf <- totalDf[order(totalDf$id, totalDf$order), ]
head(totalDf,3)
table(totalDf1$CTP_ENG_NM) %>% sort()
nrow(x = totalDf)
head(totalDf,3)

# totalDf1 <- totalDf[totalDf$CTP_ENG_NM == "Daegu"|totalDf$CTP_ENG_NM == "Gyeongsangbuk-do"|totalDf$CTP_ENG_NM == "Gyeongsangnam-do", ]
# nrow(x = totalDf1)
# head(totalDf1,3)

###########################################################
colnames(totalDf) <- c("long", "lat", "order", "hole" ,     
                        "piece", "id", "group", "CTPRVN_CD", 
                        "province", "SIG_CD", "city")
mode(totalDf$city)
mode(patient$city)
totalDf$city = as.character(totalDf$city)
totalDf$province = as.character(totalDf$province)

patient1 = aggregate(patient$patient_id, by=list(patient$city,patient$province), FUN=length)
colnames(patient1) <- c("city","province","confirmed")
totalDf = totalDf %>% left_join(patient1, by=c("city","province"))

data1 = aggregate(data$confirmed, by=list(data$city,data$province), FUN=sum)
colnames(data1) <- c("city","province","case")
totalDf = totalDf %>% left_join(data1, by=c("province","city"))

nrow(totalDf)
head(totalDf)
###########################################################

my_theme <- theme(panel.background = element_blank(),
                  axis.title = element_blank(),
                  axis.text = element_blank(),
                  axis.ticks = element_blank(),
                  plot.title = element_text("confirmed",hjust = 0.5,
                                            face = 'bold'))


########## 지역별 확진자 그래디언트
colorbar_range <- range(totalDf$confirmed)
mean_price <- mean(colorbar_range)
MAP_gradient_confirmed <- ggplot(data=totalDf) + # data layer
  geom_polygon(aes(x=long, y=lat, group=group, fill=confirmed)) +
  scale_fill_gradient2(low='gold',mid = "white",high='firebrick2',na.value = "white",limits=colorbar_range, name='Confirmed') 
x11()
MAP_gradient_confirmed


#### 집단발병 case point 찍기
MAP_point_case <-
  ggplot(data = totalDf,add=TRUE,
         mapping = aes(x = long,
                       y = lat,
                       group = group,
                       color=data$confirmed)) +
  geom_polygon(fill = 'white',
               color = 'grey') +
  my_theme +
  geom_point(data = data,
             mapping = aes(x = longitude,
                           y = latitude,
                           group = confirmed)) +
  scale_color_gradient(low="blue", high="red")
x11()
MAP_point_case


########## 집단발병 case point 그래디언트
colorbar_range <- range(totalDf$case)
mean_price <- mean(colorbar_range)
MAP_gradient_case <- ggplot(data=totalDf) + # data layer
  geom_polygon(aes(x=long, y=lat, group=group, fill=case)) +
  scale_fill_gradient2(low='gold',mid = "white",high='red',na.value = "white",limits=colorbar_range, name='Case') 
x11()
MAP_gradient_case 


### 대구 신천지 case가 너무 노답이라 제외하고 해보자
########## 집단발병 case point 그래디언트(신천지 제외)
totalDf_no_sin <- totalDf
totalDf_no_sin[totalDf_no_sin$province=="Daegu"&totalDf_no_sin$city=="Nam-gu",]$case = 0 

colorbar_range <- range(totalDf_no_sin$case)
mean_price <- mean(colorbar_range)
MAP_gradient_confirmed_no_sin <- ggplot(data=totalDf_no_sin) + # data layer
  geom_polygon(aes(x=long, y=lat, group=group, fill=case)) +
  scale_fill_gradient2(low='gold',mid = "white",high='red',na.value = "white",limits=colorbar_range, name='Case(no Sinchunzi)') 
x11()
MAP_gradient_confirmed_no_sin

###########################################################

# Simple linear
colnames(data) <- c("province","case","lat","long","city")
lin <- lm(case ~ long + lat , data = data[2:nrow(data),])

fitted <- predict(lin, newdata = totalDf_no_sin)
ehat <- totalDf_no_sin$case - fitted # residuals
totalDf_no_sin$ehat <- ehat

# residual plot
colorbar_range <- range(na.omit(totalDf_no_sin$ehat))
mean_price <- mean(colorbar_range)
MAP_gradient_ehat <- ggplot(data=totalDf_no_sin) + # data layer
  geom_polygon(aes(x=long, y=lat, group=group, fill=ehat)) +
  scale_fill_gradient2(low='blue',mid = "white",high='red',na.value = "white",limits=colorbar_range, name='e-hat') 
x11()
MAP_gradient_ehat
# 역시 잘 못맞춘다

# Fit the variogram
library(sp)
library(gstat)
library(fields)
library(classInt)
library(maps)

forSp <- na.omit(totalDf_no_sin)
sp <- SpatialPoints(coords = forSp[,2:1])
data_sp <- SpatialPointsDataFrame(sp, data=as.data.frame(forSp$ehat))
head(data_sp)

vg <- variogram(forSp.ehat ~ 1, data = data_sp)
x11()
plot(vg, xlab = "Distance", ylab = "Semi-variogram estimate", main="Evidence of Spatial correlation") 

vgangle <- variogram(forSp.ehat ~ 1, data = data_sp, alpha = c(0, 45, 90, 135))
x11()
plot(vgangle, xlab = "Distance", ylab = "Semi-variogram estimate", main="Evidence of Anisotropy")

# Fit the exponential variogram
fitvg <- fit.variogram(vg, vgm(10, "Sph", 1.2, 400))
fitvg
s2.hat <- fitvg$psill[2]
rho.hat <- fitvg$range[2]
tau2.hat <- 0.00001

x11()
plot(vg, fitvg, xlab = "Distance", ylab = "Semi-variogram estimate", main="Nonparametric & fitted Spherical variogram")


## GLS
# Fit GLS
library(nlme)
gls.fit <- gls(case ~ long+lat-1, data = data[2:nrow(data),],
               corSpher(value = c(range = rho.hat, nugget = tau2.hat/(tau2.hat+s2.hat)),
                        nugget = TRUE, form=~long+lat, fixed = TRUE))
summary(gls.fit)
summary(lin)

beta.hat <- gls.fit$coef

# We can get EBLUP by doing Kriging!
library(dplyr)
sp <- SpatialPoints(coords = data[2:nrow(data),4:3])
data_sp <- SpatialPointsDataFrame(sp, data=data[2:nrow(data),])

totalDf_no_sin1 <- totalDf_no_sin[totalDf_no_sin$province == "Daegu"|totalDf_no_sin$province == "Gyeongsangbuk-do"|totalDf_no_sin$province == "Gyeongsangnam-do", ]
target = aggregate(list(totalDf_no_sin1$long,totalDf_no_sin1$lat), by=list(totalDf_no_sin1$city,totalDf_no_sin1$province), FUN=mean)
colnames(target) <- c("city","province","long","lat")
sp <- SpatialPoints(coords = target[,4:3])
target_sp <- SpatialPointsDataFrame(sp,data=data.frame(target))

d <- as.matrix(dist(coordinates(data_sp)))
Sigma <- matrix(0, nrow = nrow(d), ncol = ncol(d))
diag(Sigma) <- s2.hat + tau2.hat
index <- d > 0 & d <= rho.hat
Sigma[index] <- s2.hat * (1 - 3/2*d[index]/rho.hat + 1/2*(d[index]/rho.hat)^3)

dcross <- rdist(coordinates(data_sp), coordinates(target_sp))

# ver2.
eta_cross <- s2.hat * exp(-abs(dcross)/rho.hat) # spatially correlated process(exponential covariance function)
Sigma_cross <- eta_cross 

X <- cbind(data[2:nrow(data),]$long, data[2:nrow(data),]$lat)
Xpred <- cbind(target$long, target$lat)

b <- t(Xpred) - t(X) %*% solve(Sigma, Sigma_cross)

ypred <- Xpred %*% beta.hat + t(Sigma_cross) %*% 
  solve(Sigma, data[2:nrow(data),]$case - X %*% beta.hat)

target$pred = ypred
head(totalDf_no_sin)
totalDf_no_sin <- totalDf_no_sin %>% left_join(target[,c(1:2,5)], by=c("province","city"))
head(totalDf_no_sin)

# pred plot
colorbar_range <- range(na.omit(totalDf_no_sin$pred))
mean_price <- mean(colorbar_range)
MAP_gradient_pred <- ggplot(data=totalDf_no_sin) + # data layer
  geom_polygon(aes(x=long, y=lat, group=group, fill=pred)) +
  scale_fill_gradient2(low='blue',mid = "white",high='red',na.value = "white",limits=colorbar_range, name='e-hat') 
x11()
MAP_gradient_pred

########## 지역별 확진자 그래디언트
colorbar_range <- range(totalDf$confirmed)
mean_price <- mean(colorbar_range)
x11()
MAP_gradient_confirmed