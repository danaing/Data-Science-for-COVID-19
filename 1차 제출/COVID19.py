# Libraries
import numpy as np
import pandas as pd
import os
import glob
import re
import sys

import plotnine
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib import animation, rc


# Setting directory
print(os.getcwd())
os.chdir("/Users/JYW/Desktop/Github/Data-Science-for-COVID-19")

# Load files
files = glob.glob('dataset/*.csv')

data = []
for i in files :
    i = i[8:]
    data.append(re.sub(".csv","",i))

for i in range(len(files)) :
    globals()[data[i]] = pd.read_csv(files[i])

data

# EDA
## Case
Case.head()
Case.tail()
Case.info()
Case.group.value_counts()
Case.infection_case.value_counts()


## PatientInfo
PatientInfo.head()

PatientInfo.info()

PatientInfo.infection_order.value_counts()


## PatientRoute
PatientRoute.head()

PatientRoute.info()


## Time
Time.head()
Time.info()

Time.tail()

## TimeAge
TimeAge.head()

TimeGender.head()
TimeGender.tail()

TimeProvince.head()
TimeProvince.tail()


## Region
Region.head()

Weather.head()

Weather.tail()

sorted(set(Weather.date))






Case.info()
PatientInfo.info()


##############################################
################ Data merge ##################
##############################################
# 1. Case + Patient
merged_pat = pd.merge(PatientInfo,Case,
        how='left',
        on=('infection_case','province','city')
        )

# 일단 루트는 선우가 하고 있으니 몇번의 이동 변화가 있는지만 반영해서 넣어보자
PatientRouteSum = PatientRoute[['patient_id', 'date']].groupby('patient_id').count()
PatientRouteSum.head()

merged_pat = pd.merge(merged_pat, PatientRouteSum, on=["patient_id"], how="left")
merged_pat.rename(columns={'date':'MoveCount'}, inplace=True)
merged_pat.head()


# 2-1. Case+Region
Case['code'] = Case['case_id'].astype('str').str[0:5].astype('int64')
Case['case_id_new'] = Case['case_id'].astype('str').str[5:8].astype('int64')

merged_CR = pd.merge(Region,Case[["code", "case_id_new", "group", "infection_case", "confirmed"]],
        how='left',
        on=('code')
        )
merged_CR.info()
merged_CR.head()

# 2-2. Region + Weather => 추후 필요하면...


# 3. Time (Crawling 필요?)
TimeProvince.head()
TimeProvince.info()
Time.head()
Time.rename(columns={'confirmed':'total_confirmed', 'released':'total_released', 'deceased':'total_deceased', 'test':'total_test', 'negative':'total_negative'}, inplace=True)
merged_time = pd.merge(TimeProvince,Time,
        how='left',
        on=('date', 'time')
        )

merged_time.info()
merged_time.head()
