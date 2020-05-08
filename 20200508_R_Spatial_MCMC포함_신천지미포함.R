rm(list=ls())

library(sp)
library(gstat)
library(fields)
library(classInt)
library(maps)
library(dplyr)

library(ggmap)
library(ggplot2)
library(rgdal)


data = read.csv("C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/dataset/Case.csv", as.is = T)
data = data[data$province == "Daegu"| data$province == "Gyeongsangbuk-do"|data$province ==  "Gyeongsangnam-do",]
data = subset(data, select=c("province","confirmed","latitude","longitude","city","infection_case"))
data = data[data[,3]!="-",]
data$confirmed = as.numeric(data$confirmed)
data$latitude = as.numeric(data$latitude)
data$longitude = as.numeric(data$longitude)
data = data[data$infection_case!="Shincheonji Church",]
head(data)

patient = read.csv("C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/dataset/PatientInfo.csv", as.is = T)
patient = patient[patient$province == "Daegu"| patient$province == "Gyeongsangbuk-do"|patient$province ==  "Gyeongsangnam-do",]
patient = subset(patient, select=c("patient_id","province","city"))
patient = patient[patient[,3]!="",]
patient = patient[patient$city!="Gyeongsan-si",]
head(patient)

###########################################################

total <- 
  rgdal::readOGR(
    dsn = 'C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19/total',
    layer = 'total',
    encoding = 'CP949')

totalDf <- fortify(model = total)
nrow(totalDf)

total@data$id <- rownames(x = total@data)

###########################################################
totalDf = totalDf %>% left_join(total@data, by = "id")
totalDf <- totalDf[totalDf$CTP_ENG_NM == "Daegu"|totalDf$CTP_ENG_NM == "Gyeongsangbuk-do"|totalDf$CTP_ENG_NM == "Gyeongsangnam-do", ]
totalDf <- totalDf[order(totalDf$id, totalDf$order), ]
head(totalDf,3)
table(totalDf$CTP_ENG_NM) %>% sort()
nrow(x = totalDf)
head(totalDf,3)

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
patient1 = patient1[!duplicated(patient1[,c('city','province')]),] # 중복 제거

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

########## 지역별 확진자 point : 얘가 TARGET!
target = aggregate(list(totalDf$long,totalDf$lat), by=list(totalDf$city,totalDf$province), FUN=mean)
colnames(target) <- c("city","province","long","lat")

target = target %>% left_join(patient1[c("city","province","confirmed")], by=c("city","province"))

MAP_point_patient <-
  ggplot(data = totalDf,add=TRUE,
         mapping = aes(x = long,
                       y = lat,
                       group = group,
                       color=target$confirmed)) +
  geom_polygon(fill = 'white',
               color = 'grey') +
  my_theme +
  geom_point(data = target,
             mapping = aes(x = long,
                           y = lat,
                           group = confirmed)) +
  scale_color_gradient(low="blue", high="red")
x11()
MAP_point_patient

### target을 gradient로!!
colorbar_range <- range(totalDf$confirmed)
mean_price <- mean(colorbar_range)
MAP_gradient_patient <- ggplot(data=totalDf) + # data layer
  geom_polygon(aes(x=long, y=lat, group=group, fill=confirmed)) +
  scale_fill_gradient2(low='gold',mid = "white",high='firebrick2',na.value = "white",limits=colorbar_range, name='Confirmed') 
x11()
MAP_gradient_patient



# Simple linear
colnames(data) <- c("province","case","lat","long","city","infection_case")
lin <- lm(case ~ long + lat , data = data)

fitted <- predict(lin, newdata = totalDf)
ehat <- totalDf$case - fitted # residuals
totalDf$ehat <- ehat


# Fit the variogram
library(sp)
library(gstat)
library(fields)
library(classInt)
library(maps)

forSp <- na.omit(totalDf)
sp <- SpatialPoints(coords = forSp[,2:1])
data_sp <- SpatialPointsDataFrame(sp, data=as.data.frame(forSp$ehat))
head(data_sp)

vg <- variogram(forSp.ehat ~ 1, data = data_sp)
x11()
plot(vg, xlab = "Distance", ylab = "Semi-variogram estimate", main="Evidence of Spatial correlation") 

# Fit the exponential variogram
fitvg <- fit.variogram(vg, vgm(3000, "Sph", 0.3, 2000))
fitvg
s2.hat <- fitvg$psill[2]
rho.hat <- fitvg$range[2]
tau2.hat <-  fitvg$psill[1]


## GLS
# Fit GLS
library(nlme)
gls.fit <- gls(case ~ long+lat-1, data = data,
               corSpher(value = c(range = rho.hat, nugget = tau2.hat/(tau2.hat+s2.hat)),
                        nugget = TRUE, form=~long+lat, fixed = TRUE))
summary(gls.fit)
summary(lin)

beta.hat <- gls.fit$coef

# We can get EBLUP by doing Kriging!
sp <- SpatialPoints(coords = data[,4:3])
data_sp <- SpatialPointsDataFrame(sp, data=data)

sp <- SpatialPoints(coords = target[,4:3])
target_sp <- SpatialPointsDataFrame(sp,data=data.frame(target))

d <- as.matrix(dist(coordinates(data_sp)))
Sigma <- matrix(0, nrow = nrow(d), ncol = ncol(d))
diag(Sigma) <- s2.hat + tau2.hat
index <- d > 0 & d <= rho.hat
Sigma[index] <- s2.hat * (1 - 3/2*d[index]/rho.hat + 1/2*(d[index]/rho.hat)^3)

dcross <- rdist(coordinates(data_sp), coordinates(target_sp))

eta_cross <- s2.hat * exp(-abs(dcross)/rho.hat) # spatially correlated process(exponential covariance function)
Sigma_cross <- eta_cross 

X <- cbind(data$long, data$lat)
Xpred <- cbind(target$long, target$lat)

b <- t(Xpred) - t(X) %*% solve(Sigma, Sigma_cross)

ypred <- Xpred %*% beta.hat + t(Sigma_cross) %*% 
  solve(Sigma, data$case - X %*% beta.hat)

target$pred = ypred
nrow(target)
head(target)

## Point로 그리기
MAP_point_pred <-
  ggplot(data = totalDf,add=TRUE,
         mapping = aes(x = long,
                       y = lat,
                       group = group,
                       color=target$pred)) +
  geom_polygon(fill = 'white',
               color = 'grey') +
  my_theme +
  geom_point(data = target,
             mapping = aes(x = long,
                           y = lat,
                           group = pred)) +
  scale_color_gradient(low="blue", high="red")
x11()
MAP_point_pred

### gradient로 그리기
totalDf = totalDf %>% left_join(target[,c("city","province","pred")], by = c("city","province"))
colorbar_range <- range(totalDf$pred)
mean_price <- mean(colorbar_range)
MAP_gradient_pred <- ggplot(data=totalDf) + # data layer
  geom_polygon(aes(x=long, y=lat, group=group, fill=pred)) +
  scale_fill_gradient2(low='gold',mid = "white",high='firebrick2',na.value = "white",limits=colorbar_range, name='Confirmed') 
x11()
MAP_gradient_pred





### MCMC

## Prior parameters

m.beta <- rep(0, 3); V.beta <- 100000 * diag(3) # variance is flat(non-information prior)
a.s2 <- 0.001; b.s2 <- 0.001
a.t2 <- 0.001; b.t2 <- 0.001

rhoseq <- seq(0.01, 300, length = 100)
plot(rhoseq, dgamma(rhoseq, shape = 1, scale = 1)) # old prior for rho
m.rho <- 100; v.rho <- 5000
b.rho <- v.rho/m.rho; a.rho <- m.rho/b.rho
plot(rhoseq, dgamma(rhoseq, shape = a.rho, scale = b.rho), type = "l") # new prior for rho

## Setup, storage, and starting values

y <- data$case
n <- nrow(data); m <- nrow(target)
d <- rdist.earth(coordinates(data))
X <- cbind(rep(1, n), data$long, data$lat)
Xpred <- cbind(rep(1, m), target$long, target$lat)

B <- 10000

beta.samps <- matrix(NA, nrow = 3, ncol = B)
beta.samps[,1] <- coef(lin)

s2.samps <- t2.samps <- rho.samps <- rep(NA, B)
s2.samps[1] <- fitvg$psill[2]
rho.samps[1] <- fitvg$range[2]
t2.samps[1] <- fitvg$psill[1]

eta.obs.samps <- matrix(NA, nrow = n, ncol = B) # latent process
dim(eta.obs.samps)
# 200: observation number 
# -> If observation number gets higher, latent process becomes high dimension simultaneously
v.prop <- 100^2

## MCMC sampler

Gamma <- exp(-d/rho.samps[1]) # initalize Gamma matrix
Ginv <- solve(Gamma)
# solve 함수를 iteration을 돌 때마다 먹이는 거보다 
# Ginv에 저장해두는 것이 큰 데이터일수록 MCMC가 빠르다


# Let's get 
# posterior: f( eta_obs, beta, s2, t2, rho | Y )
#

library(classInt)
library(fields)
library(maps)
library(sp)
library(gstat)
library(geoR)
library(mvtnorm)
library(MCMCpack)
library(coda)

for(i in 2:B){
  
  if(i%%100==0) print(i)
  # 100번마다 print해줌
  
  ## eta_obs | Rest -> also the Normal (because eta_obs is Gaussian)
  # eta_obs|beta, s2, t2, rho -> Noraml
  V <- solve(diag(n)/t2.samps[i-1] + Ginv/s2.samps[i-1])
  m <- V %*% (y/t2.samps[i-1] + Ginv %*% X %*% 
                beta.samps[,i-1] / s2.samps[i-1])
  eta.obs.samps[,i] <- rmvnorm(1, mean = m, sigma = V, method = "svd")
  
  
  ## beta | Rest
  # beta|eta_obs, s2, t2, rho -> Noraml
  V <- solve(t(X) %*% Ginv %*% X / s2.samps[i-1] + solve(V.beta))
  m <- V %*% (t(X) %*% Ginv %*% eta.obs.samps[,i] / 
                s2.samps[i-1] + solve(V.beta, m.beta))
  beta.samps[,i] <- rmvnorm(1, mean = m, sigma = V, method = "svd")
  
  
  ## s2 | Rest
  # s2 | eta_obs, beta, t2, rho -> Inverse Gamma
  a <- a.s2 + n/2
  resid <- eta.obs.samps[,i] - X %*% beta.samps[,i]
  b <- b.s2 + t(resid) %*% Ginv %*% resid /2
  s2.samps[i] <- rinvgamma(1, a, b)
  
  ## t2 | Rest
  # t2 | eta_obs, beta, s2, rho -> Inverse Gamma
  a <- a.t2 + n/2
  resid <- y - eta.obs.samps[,i]
  b <- b.t2 + t(resid) %*% resid / 2
  t2.samps[i] <- rinvgamma(1, a, b)
  
  ## rho | Rest -> There is a no closed-form
  # Using Metropolis-Hasting !!
  
  # Visualize posterior surface
  # The ratio of this function at rho.cand to rho.samps[i-1] is what determines r
  if(FALSE){
    prho <- sapply(rhoseq, function(rho){
      dmvnorm(eta.obs.samps[,i], mean = X %*% beta.samps[,i], 
              sigma = s2.samps[i] * exp(-d/rho), log = TRUE) +
        dgamma(rho, shape = a.rho, scale = b.rho, log = TRUE)})
    plot(rhoseq, exp(prho), type = "l")
  }
  
  rho.cand <- rnorm(1, mean = rho.samps[i-1], sd = sqrt(v.prop))
  # generate candidate of rho: q( ) in the lecture note
  # v.prop = 1,000 in this case 
  # -> if this value gets smaller 
  # -> acceptance rate becomes higher 
  # -> but correlation also gets higher among the MCMC sample
  
  if(rho.cand < 0){ # automatically reject
    rho.samps[i] <- rho.samps[i-1]
  } else {
    lik1 <- dmvnorm(eta.obs.samps[,i], mean = X %*% beta.samps[,i],
                    sigma = s2.samps[i] * exp(-d/rho.cand), log = TRUE)
    lik2 <- dmvnorm(eta.obs.samps[,i], mean = X %*% beta.samps[,i],
                    sigma = s2.samps[i] * exp(-d/rho.samps[i-1]), log = TRUE)
    p1 <- dgamma(rho.cand, shape = a.rho, scale = b.rho, log = TRUE)
    p2 <-   dgamma(rho.samps[i-1], shape = a.rho, scale = b.rho, log = TRUE)
    r <- exp(lik1 + p1 - lik2 - p2)
    if(runif(1) < r){ # accept
      rho.samps[i] <- rho.cand
      Gamma <- exp(-d/rho.cand) 
      Ginv <- solve(Gamma)
    } else { # reject
      rho.samps[i] <- rho.samps[i-1]
    }
  }
  
}

## diagnostic
plot(beta.samps[1,], type = "l")
plot(s2.samps, type = "l")
plot(rho.samps, type = "l")

length(unique(rho.samps))/B

plot(t2.samps, type = "l")
plot(eta.obs.samps[1,], type = "l")

burnin <- 2000
s2.final <- s2.samps[-(1:burnin)]
t2.final <- t2.samps[-(1:burnin)]
beta.final <- beta.samps[,-(1:burnin)]
eta.obs.final <- eta.obs.samps[,-(1:burnin)]
rho.final <- rho.samps[-(1:burnin)]

acf(s2.final)
acf(t2.final)
acf(beta.final[1,])
acf(eta.obs.final[1,])
acf(rho.final)
# rho ACF quite high yet


## Prediction

dcross <- rdist.earth(coordinates(data_sp), coordinates(target_sp))
dpred <- rdist.earth(coordinates(target_sp))

index <- seq(1, B-burnin, by = 20) # which samples to use (thinning)
eta.pred <- matrix(NA, nrow = nrow(target_sp), ncol = length(index))


# For each of the parameter,
# calculate the conditional distribution of Normal(m, V)
# can be varied by MCMC samples
length(index)
# Just do for only 45 example case

for(i in 1:length(index)){
  print(i)
  j <- index[i]
  
  # Construct the covariance matrices
  Gamma <- exp(-d/rho.samps[j]) 
  Ginv <- solve(Gamma)
  g <- exp(-dcross/rho.samps[j])
  Gpred <- exp(-dpred/rho.samps[j])
  m <- Xpred %*% beta.final[,j] + t(g) %*% Ginv %*% 
    (y - X %*% beta.final[,j])
  
  V <- s2.final[j] * (Gpred - t(g)%*%Ginv%*%g)
  eta.pred[,i] <- rmvnorm(1, m, V, method = "svd")
}

## Find pointwise posterior means and sds
eta.pred.m <- apply(eta.pred, 1, mean)
eta.pred.sd <- apply(eta.pred, 1, sd)

target$pred.MCMC <- eta.pred.m
target$pred.MCMC.sd <- eta.pred.sd

## point로 그리기
MAP_point_pred_MCMC <-
  ggplot(data = totalDf,add=TRUE,
         mapping = aes(x = long,
                       y = lat,
                       group = group,
                       color=target$pred.MCMC)) +
  geom_polygon(fill = 'white',
               color = 'grey') +
  my_theme +
  geom_point(data = target,
             mapping = aes(x = long,
                           y = lat,
                           group = pred.MCMC)) +
  scale_color_gradient(low="blue", high="red")
x11()
MAP_point_pred_MCMC

### gradient로 그리기
totalDf = totalDf %>% left_join(target[,c("city","province","pred.MCMC")], by = c("city","province"))
colorbar_range <- range(totalDf$pred.MCMC)
mean_price <- mean(colorbar_range)
MAP_gradient_pred_MCMC <- ggplot(data=totalDf) + # data layer
  geom_polygon(aes(x=long, y=lat, group=group, fill=pred.MCMC)) +
  scale_fill_gradient2(low='gold',mid = "white",high='firebrick2',na.value = "white",limits=colorbar_range, name='Confirmed') 
x11()
MAP_gradient_pred_MCMC


### Plotting
x11()
MAP_gradient_patient
x11()
MAP_gradient_pred
x11()
MAP_gradient_pred_MCMC
x11()
MAP_point_patient
x11()
MAP_point_pred
x11()
MAP_point_pred_MCMC


