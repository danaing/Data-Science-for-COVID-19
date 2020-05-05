import pandas as pd
import numpy as np
import os


os.getcwd()
os.chdir('C:\\Users\\Danah\\Documents\\GitHub\\Data-Science-for-COVID-19\\Naver_News_keyword_Crawling\\newstitle_tokkened\\')



mask = pd.read_csv('newstitle_mask_tokkened.txt', sep='\t')
