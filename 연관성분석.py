import pandas as pd
import numpy as np
import os
from mlxtend.preprocessing import TransactionEncoder
from mlxtend.frequent_patterns import apriori
from mlxtend.frequent_patterns import association_rules

os.getcwd()
os.chdir('C:\\Users\\Danah\\Documents\\GitHub\\Data-Science-for-COVID-19\\Naver_News_keyword_Crawling\\newstitle_tokkened\\')


dalgona = pd.read_csv('newstitle_dalgona_tokkened.txt', sep='\t')
mask = pd.read_csv('newstitle_mask_tokkened.txt', sep='\t')
society = pd.read_csv('newstitle_society_tokkened.txt', sep='\t')
son = pd.read_csv('newstitle_son_tokkened.txt', sep='\t')
uhan = pd.read_csv('newstitle_uhan_tokkened.txt', sep='\t')
zipcock = pd.read_csv('newstitle_zipcock_tokkened.txt', sep='\t')
harujongil = pd.read_csv('newstitle_harujongil_tokkened.txt', sep='\t')
COVID = pd.read_csv('newstitle_COVID_tokkened.txt', sep='\t')
corona = pd.read_csv('newstitle_corona_tokkened.txt', sep='\t')

##### corona #####
corona = pd.read_csv('newstitle_corona_tokkened.txt', sep='\t')
corona.head()
dataset = corona.title_imp_tokken
dataset.head()

lst = []
for i in range(len(dataset)) :
    a = dataset[i][1:-1]
    lst.append(eval("["+a+"]"))

dataset = lst

te = TransactionEncoder()  #나온 item을 column으로 두고, 벡터에 item을 가지고 있으면 1, 없으면 0으로 표현하도록 Encoding함
te_ary = te.fit(dataset).transform(dataset)
df = pd.DataFrame(te_ary, columns=te.columns_) #데이터프레임으로 변경
df

df.shape

# 지지도
frequent_itemsets = apriori(df, min_support=0.8, use_colnames=True)
frequent_itemsets

# 신뢰도
association_rules(frequent_itemsets, metric="confidence", min_threshold=0.5)



##### mask #####
mask = pd.read_csv('newstitle_mask_tokkened.txt', sep='\t')
mask.head()
dataset = mask.title_imp_tokken
dataset.head()

lst = []
for i in range(len(dataset)) :
    a = dataset[i][1:-1]
    lst.append(eval("["+a+"]"))

dataset = lst

te = TransactionEncoder()  #나온 item을 column으로 두고, 벡터에 item을 가지고 있으면 1, 없으면 0으로 표현하도록 Encoding함
te_ary = te.fit(dataset).transform(dataset)
df = pd.DataFrame(te_ary, columns=te.columns_) #데이터프레임으로 변경

df.shape

# 지지도
frequent_itemsets = apriori(df, min_support=0.5, use_colnames=True)
frequent_itemsets['length'] = frequent_itemsets['itemsets'].apply(lambda x: len(x))
frequent_itemsets.sort_values(by='support', ascending=False)
frequent_itemsets_2 = frequent_itemsets[(frequent_itemsets['length']==2)].sort_values(by='support', ascending=False)
frequent_itemsets_2

# 신뢰도
association_rules(frequent_itemsets, metric="confidence", min_threshold=0.7).sort_values(by='lift', ascending=False)
