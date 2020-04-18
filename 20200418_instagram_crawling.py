from bs4 import BeautifulSoup
import selenium.webdriver as webdriver
import urllib.parse
from urllib.request import Request, urlopen
from time import sleep
import pandas as pd
import os

os.chdir("C:/Users/JYW/Desktop/Github/Data-Science-for-COVID-19")

url_list = {"test":"https://www.instagram.com/explore/tags/%ED%8F%89%EC%B0%BD%EB%8F%99%EC%82%BC%EC%84%B1%EC%95%84%ED%8C%8C%ED%8A%B8/",
            "oohan":"https://www.instagram.com/explore/tags/%EC%9A%B0%ED%95%9C/",
            "dalgona":"https://www.instagram.com/explore/tags/%EB%8B%AC%EA%B3%A0%EB%82%98%EC%BB%A4%ED%94%BC/",
            "harooJongil":"https://www.instagram.com/explore/tags/%ED%95%98%EB%A3%A8%EC%A2%85%EC%9D%BC/",
            "zipcock":"https://www.instagram.com/explore/tags/%EC%A7%91%EC%BD%95/",
            "SaHeojuck":"https://www.instagram.com/explore/tags/%EC%82%AC%ED%9A%8C%EC%A0%81%EA%B1%B0%EB%A6%AC%EB%91%90%EA%B8%B0/",
            "mask":"https://www.instagram.com/explore/tags/%EB%A7%88%EC%8A%A4%ED%81%AC/",
            "SonSSitGi":"https://www.instagram.com/explore/tags/%EC%86%90%EC%94%BB%EA%B8%B0/"}

for j in range(0,len(url_list)) :
    print(list(url_list.keys())[j]+"키워드 작업 중")

    url = list(url_list.values())[j]
    driver = webdriver.Chrome('C:/Users/JYW/Documents/chromedriver_win32/chromedriver.exe')

    driver.get(url)
    sleep(5)

    SCROLL_PAUSE_TIME = 2.0
    reallink = []

    while True:
        pageString = driver.page_source
        bsObj = BeautifulSoup(pageString, "lxml")

        for link1 in bsObj.find_all(name="div",attrs={"class":"Nnq7C weEfm"}):
            title = link1.select('a')[0]
            real = title.attrs['href']
            reallink.append(real)
            title = link1.select('a')[1]
            real = title.attrs['href']
            reallink.append(real)
            title = link1.select('a')[2]
            real = title.attrs['href']
            reallink.append(real)

        last_height = driver.execute_script("return document.body.scrollHeight")
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        sleep(SCROLL_PAUSE_TIME)
        new_height = driver.execute_script("return document.body.scrollHeight")
        if new_height == last_height:
            driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            sleep(SCROLL_PAUSE_TIME)
            new_height = driver.execute_script("return document.body.scrollHeight")
            if new_height == last_height:
                break

            else:
                last_height = new_height
                continue
    csvtext = []

    reallinknum = len(reallink)
    print("총"+str(reallinknum)+"개의 데이터.")

    try:
        for i in range(0,reallinknum):
            csvtext.append([])
            req = Request('https://www.instagram.com/p'+reallink[i],headers={'User-Agent': 'Mozilla/5.0'})

            webpage = urlopen(req).read()
            soup = BeautifulSoup(webpage,"lxml",from_encoding='utf-8')
            soup1 = soup.find("meta",attrs={"property":"og:description"})

            reallink1 = soup1['content']
            reallink1 = reallink1[reallink1.find("@")+1:reallink1.find(")")]
            reallink1 = reallink1[:20]
            if reallink1 == '':
                reallink1 = 'Null'
            csvtext[i].append(reallink1)

            for reallink2 in soup.find_all("meta",attrs={"property":"instapp:hashtags"}):
                reallink2 = reallink2['content']
                csvtext[i].append(reallink2)

            data = pd.DataFrame(csvtext)
            data.to_csv(('insta_'+list(url_list.keys())[j]+'.txt'), encoding='utf-8')

    except:
        print("오류발생"+str(i+1)+"개의 데이터를 저장합니다.")

        data = pd.DataFrame(csvtext)
        data.to_csv(('insta_'+list(url_list.keys())[j]+'.txt'), encoding='utf-8',header=None)

    print(list(url_list.keys())[j]+"키워드 작업 완료")
