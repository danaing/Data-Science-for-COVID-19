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
import os

# twitter = Twitter()
okt = Okt()

os.getcwd()
os.chdir('C:\\Users\\Danah\\Documents\\GitHub\\Data-Science-for-COVID-19\\DA_COMMIT1_Crawling\\')

#자가격리도 해보기
################ paging 크롤링 ################
keyword_dict = ['집콕', '하루종일', 'COVID', '코로나', '우한', '사회적거리두기', '마스크', '손씻기', '달고나커피']
keyword = keyword_dict[0]
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

    file_csv = 'newstitle_' + keyword + '.csv'
    file_txt = 'newstitle_' + keyword + '.txt'

    news.to_csv(file_csv, index=False)
    news.to_csv(file_txt, index=False, header=True, sep="\t")
#==================== Crawling End ====================#

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

list(news['title']).apply(tokenizer_okt_pos)

news['title_tokken'] = news['title'].apply(tokenizer_okt_pos)
news['title_imp_tokken'] = news['title_tokken'].apply(imp_tokken)


list=[]
for d in news.title_imp_tokken :
    for a in d:
        list.append(a)
count = Counter(list)

title_count = dict(count.most_common())
title_count


################ word cloud ################
from wordcloud import WordCloud
import matplotlib.pyplot as plt

%matplotlib inline
import matplotlib
from IPython.display import set_matplotlib_formats
matplotlib.rc('font',family = 'Malgun Gothic')
set_matplotlib_formats('retina')
matplotlib.rc('axes',unicode_minus = False)

wordcloud = WordCloud(font_path = 'C:/Windows/Fonts/malgun.ttf', background_color='white',colormap = "Accent_r", width=1500, height=1000).generate_from_frequencies(title_count)

fig = plt.figure(1,figsize=(13, 13))
plt.imshow(wordcloud)
plt.axis('off')
plt.savefig('fig.png', bbox_inces='tight', dpi=300)
plt.close()
wordcloud.to_file("img.png")
