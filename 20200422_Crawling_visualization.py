import pandas as pd
import os
os.chdir("C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19")

data = pd.read_csv("insta_csvtext2.csv")
data = data.iloc[:,1:]

location = data.iloc[:,0]
location = [x for x in location if str(x) != '[']
location = [x for x in location if str(x) != '0']

time = data.iloc[:,1]

hash = data.iloc[:,2:]
hash = list(hash.values.flatten())
hash = [x for x in hash if str(x) != 'nan']
hash
len(hash)


###### 1. location
loc = pd.DataFrame(pd.Series(location).value_counts())
loc.head(30)


###### 2. Time
time = time.value_counts().sort_index()
time


###### 3. Hashtags
pd.Series(hash).value_counts().head(40)

ban_list = ["코로나","코로나19","일회용마스크","미세먼지마스크","필터마스크","닥터홍헤파필터","닥터홍마스크필터",
            "맞팔","좋아요","소통","선팔","좋아요반사","좋반","팔로우","인친","맞팔해요"]
hash = [x for x in hash if x not in ban_list]
pd.Series(hash).value_counts().head(40)




import re
from wordcloud import WordCloud, STOPWORDS
import matplotlib as mpl
import matplotlib.pyplot as plt
from IPython.display import set_matplotlib_formats
mpl.rc('font',family = 'Malgun Gothic')
from collections import Counter

hash = Counter(hash)
hash_count = dict(hash.most_common(1000))

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='white',colormap = "Accent_r", width=1500, height=1000).generate_from_frequencies(hash_count)

fig = plt.figure(1,figsize=(13,13))
fig = plt.axis('off')
plt.imshow(wordcloud)


img = np.array(Image.open('covid.jpg'))

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='black',colormap = "Accent_r",  mask = img, margin=1).generate_from_frequencies(hash_count)
wordcloud = wordcloud.to_array()

fig = plt.figure(1,figsize=(13,13))
fig = plt.axis('off')
plt.imshow(wordcloud, interpolation="bilinear")
