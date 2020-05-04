import requests as req
from bs4 import BeautifulSoup as bs
import os
from selenium import webdriver
import pandas as pd
from html_table_parser import parser_functions as parser
import numpy as np
import csv
from konlpy.tag import Twitter #명사를 분리 추출하기 위해 한국어 형태소 분석기
from konlpy.tag import Okt
from collections import Counter
import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings(action='ignore')
okt = Okt()

# twitter = Twitter()


os.getcwd()
os.chdir('C:\\Users\\Danah\\Documents\\GitHub\\Data-Science-for-COVID-19\\Naver_News_keyword_Crawling\\')

#자가격리도 해보기
################ paging 크롤링 ################
keyword_dict = ['집콕', '하루종일', 'COVID', '코로나', '우한', '사회적거리두기', '마스크', '손씻기', '달고나커피']
whole_source = ""


### 2020.01.01~2020.04.18 기사 최대 100개씩
date_dict = {'2020.01.': range(0,31), '2020.02.': range(0,29), '2020.03.': range(0,31), '2020.04.': range(0,18)}

list(date_dict.keys())
list(date_dict.values())


#==================== Crawling Start ====================#
for keyword in keyword_dict :
    news = pd.DataFrame()

    # 월
    for m in range(0,4) :
        month = list(date_dict.keys())[m]
        total_title_cnt = 0
        # 일
        for d in range(0,len(list(date_dict.values())[m])):
            date = month + format(d+1).zfill(2)

            whole_source = ""
            for page_number in range(0, 10):   # 최대 100개 기사
                base_url = 'https://search.naver.com/search.naver?where=news&query=' + keyword + '&sm=tab_opt&sort=0&photo=0&field=0&reporter_article=&pd=3&mynews=0&refresh_start=0&related=0'
                url = base_url + '&ds=' + date + '&de=' + date + '&start='+ str(page_number*10+1)
                res = req.get(url)
                whole_source = whole_source + res.text

            soup = bs(whole_source, 'html.parser')
            title_tmp = soup.select('li > dl > dt > a._sp_each_title')

            title = [i.text for i in title_tmp]
            print(keyword,'키워드로',date,'날짜의 ',len(title), '개 기사를 크롤링했습니다.')

            news_tmp = pd.DataFrame([[ date, title]],  columns=['date', 'title'])
            news = pd.concat([news, news_tmp])
            total_title_cnt = total_title_cnt + len(title)

        print(month,'에 총', total_title_cnt, '개 기사를 크롤링했습니다.')

    file_csv = 'newstitle_' + keyword + '_4월.csv'
    file_txt = 'newstitle_' + keyword + '_4월.txt'

    news.to_csv(file_csv, index=False)
    news.to_csv(file_txt, index=False, header=True, sep="\t")
#==================== Crawling End ====================#


#================== file check =======================#
os.getcwd()
os.chdir('C:\\Users\\Danah\\Documents\\GitHub\\Data-Science-for-COVID-19\\Naver_News_keyword_Crawling\\')


dalgona = pd.read_csv('newstitle_dalgona.txt', sep='\t')
mask = pd.read_csv('newstitle_mask.txt', sep='\t')
society = pd.read_csv('newstitle_society.txt', sep='\t')
son = pd.read_csv('newstitle_son.txt', sep='\t')
uhan = pd.read_csv('newstitle_uhan.txt', sep='\t')
zipcock = pd.read_csv('newstitle_zipcock.txt', sep='\t')
corona = pd.read_csv('newstitle_corona.txt', sep='\t')
harujongil = pd.read_csv('newstitle_harujongil.txt', sep='\t')
COVID = pd.read_csv('newstitle_COVID.txt', sep='\t')


################ Tokenizer ################

def tokenizer_okt_pos(doc):
    return okt.pos(doc)

def tokenizer_twitter_pos(doc):
    return twitter.pos(doc, norm=True, stem=True)

def imp_tokken(sentence):
    noun_adj_list = []
    for word, tag in sentence:
        if tag in ['Noun','Adjective']:
            noun_adj_list.append(word)
    return noun_adj_list

def list_appending(lists):
    list_append=[]
    for d in lists :
        for a in d:
            list_append.append(a)
    return list_append


dalgona['title_tokken'] = dalgona['title'].apply(tokenizer_okt_pos)
dalgona['title_imp_tokken'] = dalgona['title_tokken'].apply(imp_tokken)

mask['title_tokken'] = mask['title'].apply(tokenizer_okt_pos)
mask['title_imp_tokken'] = mask['title_tokken'].apply(imp_tokken)

society['title_tokken'] = society['title'].apply(tokenizer_okt_pos)
society['title_imp_tokken'] = society['title_tokken'].apply(imp_tokken)

son['title_tokken'] = son['title'].apply(tokenizer_okt_pos)
son['title_imp_tokken'] = son['title_tokken'].apply(imp_tokken)

uhan['title_tokken'] = uhan['title'].apply(tokenizer_okt_pos)
uhan['title_imp_tokken'] = uhan['title_tokken'].apply(imp_tokken)

zipcock['title_tokken'] = zipcock['title'].apply(tokenizer_okt_pos)
zipcock['title_imp_tokken'] = zipcock['title_tokken'].apply(imp_tokken)

corona['title_tokken'] = corona['title'].apply(tokenizer_okt_pos)
corona['title_imp_tokken'] = corona['title_tokken'].apply(imp_tokken)

harujongil['title_tokken'] = harujongil['title'].apply(tokenizer_okt_pos)
harujongil['title_imp_tokken'] = harujongil['title_tokken'].apply(imp_tokken)

COVID['title_tokken'] = COVID['title'].apply(tokenizer_okt_pos)
COVID['title_imp_tokken'] = COVID['title_tokken'].apply(imp_tokken)

# check
COVID.head()

# 토크나이져 결과 csv 저장
dalgona.to_csv('newstitle_dalgona_tokkened.txt', index=False, header=True, sep="\t")
mask.to_csv('newstitle_mask_tokkened.txt', index=False, header=True, sep="\t")
society.to_csv('newstitle_society_tokkened.txt', index=False, header=True, sep="\t")
son.to_csv('newstitle_son_tokkened.txt', index=False, header=True, sep="\t")
uhan.to_csv('newstitle_uhan_tokkened.txt', index=False, header=True, sep="\t")
zipcock.to_csv('newstitle_zipcock_tokkened.txt', index=False, header=True, sep="\t")
corona.to_csv('newstitle_corona_tokkened.txt', index=False, header=True, sep="\t")
harujongil.to_csv('newstitle_harujongil_tokkened.txt', index=False, header=True, sep="\t")
COVID.to_csv('newstitle_COVID_tokkened.txt', index=False, header=True, sep="\t")




################ imp_tokken count ################

count = Counter(list_appending(corona['title_imp_tokken']))
title_count = dict(count.most_common())
title_count




################ word cloud ################
from wordcloud import WordCloud
import matplotlib.pyplot as plt
os.chdir('C:\\Users\\Danah\\Documents\\GitHub\\Data-Science-for-COVID-19\\Naver_News_keyword_Crawling\\wordcloud_img\\')

%matplotlib inline
import matplotlib
from IPython.display import set_matplotlib_formats
matplotlib.rc('font',family = 'Malgun Gothic')
set_matplotlib_formats('retina')
matplotlib.rc('axes',unicode_minus = False)

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='white',colormap = "Accent_r", width=1500, height=1000).generate_from_frequencies(title_count)


fig = plt.figure(1,figsize=(13, 13))
fig = plt.axis('off')
plt.imshow(wordcloud)
wordcloud.to_file("img.png")
plt.close()





#===================== 코로나 살펴보기 =====================#


# 1월
jan = ( corona.date >= '2020.01.01') & (corona.date < '2020.02.01')
count = Counter(list_appending(corona.loc[jan,'title_imp_tokken']))
title_count = dict(count.most_common())

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='white',colormap = "Accent_r", width=1500, height=1000).generate_from_frequencies(title_count)

fig = plt.figure(1,figsize=(13, 13))
fig = plt.axis('off')
plt.imshow(wordcloud)
wordcloud.to_file("코로나_1월.png")
plt.close()

# 2월
feb = ( corona.date >= '2020.02.01') & (corona.date < '2020.03.01')
count = Counter(list_appending(corona.loc[feb,'title_imp_tokken']))
title_count = dict(count.most_common())

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='white',colormap = "Accent_r", width=1500, height=1000).generate_from_frequencies(title_count)

fig = plt.figure(1,figsize=(13, 13))
fig = plt.axis('off')
plt.imshow(wordcloud)
wordcloud.to_file("코로나_2월.png")
plt.close()

# 3월
mar = ( corona.date >= '2020.03.01') & (corona.date < '2020.04.01')
count = Counter(list_appending(corona.loc[mar,'title_imp_tokken']))
title_count = dict(count.most_common())

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='white',colormap = "Accent_r", width=1500, height=1000).generate_from_frequencies(title_count)

fig = plt.figure(1,figsize=(13, 13))
fig = plt.axis('off')
plt.imshow(wordcloud)
wordcloud.to_file("코로나_3월.png")
plt.close()




#===================== 하루종일 살펴보기 =====================#

harujongil['title_tokken'] = harujongil['title'].apply(tokenizer_okt_pos)
harujongil['title_imp_tokken'] = harujongil['title_tokken'].apply(imp_tokken)
harujongil.head()

count = Counter(list_appending(harujongil['title_imp_tokken']))
title_count = dict(count.most_common())
title_count

################ word cloud ################
from wordcloud import WordCloud
import matplotlib.pyplot as plt
os.chdir('C:\\Users\\Danah\\Documents\\GitHub\\Data-Science-for-COVID-19\\Naver_News_keyword_Crawling\\wordcloud_img\\')

%matplotlib inline
import matplotlib
from IPython.display import set_matplotlib_formats
matplotlib.rc('font',family = 'Malgun Gothic')
set_matplotlib_formats('retina')
matplotlib.rc('axes',unicode_minus = False)

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='white',colormap = "Accent_r", width=1500, height=1000).generate_from_frequencies(title_count)


fig = plt.figure(1,figsize=(13, 13))
fig = plt.axis('off')
plt.imshow(wordcloud)
wordcloud.to_file("하루종일.png")
plt.close()


# 1월
jan = ( harujongil.date >= '2020.01.01') & (harujongil.date < '2020.02.01')
count = Counter(list_appending(harujongil.loc[jan,'title_imp_tokken']))
title_count = dict(count.most_common())

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='white',colormap = "Accent_r", width=1500, height=1000).generate_from_frequencies(title_count)

fig = plt.figure(1,figsize=(13, 13))
fig = plt.axis('off')
plt.imshow(wordcloud)
wordcloud.to_file("하루종일_1월.png")
plt.close()

# 2월
feb = ( harujongil.date >= '2020.02.01') & (harujongil.date < '2020.03.01')
count = Counter(list_appending(harujongil.loc[feb,'title_imp_tokken']))
title_count = dict(count.most_common())

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='white',colormap = "Accent_r", width=1500, height=1000).generate_from_frequencies(title_count)

fig = plt.figure(1,figsize=(13, 13))
fig = plt.axis('off')
plt.imshow(wordcloud)
wordcloud.to_file("하루종일_2월.png")
plt.close()

# 3월
mar = ( harujongil.date >= '2020.03.01') & (harujongil.date < '2020.04.01')
count = Counter(list_appending(harujongil.loc[mar,'title_imp_tokken']))
title_count = dict(count.most_common())

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='white',colormap = "Accent_r", width=1500, height=1000).generate_from_frequencies(title_count)

fig = plt.figure(1,figsize=(13, 13))
fig = plt.axis('off')
plt.imshow(wordcloud)
wordcloud.to_file("하루종일_3월.png")
plt.close()



#===================== 언급량의 변화 =====================#

harujongil.title_imp_tokken.apply(Counter)


a=harujongil.title_imp_tokken.apply(Counter)
a
a[0].most_common()
a[1].most_common(10)
a[2].most_common(10)
a[3].most_common(10)
a[95].most_common(10)



['ARP' + str(i) for i in range(1,16)]

COVID = pd.read_csv('newstitle_COVID.txt', sep='\t')


[str(i) for i in range(1,16)]

[str(COVID.date[i])[0:4] for i in range(len(COVID))]
