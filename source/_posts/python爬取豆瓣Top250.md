---
title: python爬取豆瓣Top250
date: 2022-11-19 20:46:12
tags:
  - 爬虫
catagory:
  - python

---

爬虫入门实例

<!-- more -->

思路很简单，先将原网页爬取出来，然后用正则表达式、BeautifulSoup和xpath3种方法提取想要的信息，这里暂时先只爬取电影名、导演、评分和标语。
```python
import re
import csv
import requests
from lxml import etree
from bs4 import BeautifulSoup
from urllib.parse import urlencode

root = 'https://movie.douban.com/top250'
para = {'start': 0, 'filter': ''}
headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)'
                         ' Chrome/92.0.4515.107 Safari/537.36 Edg/92.0.902.55'}

# 正则表达式
writedata = []
pattern = re.compile(r'<li>.*?<div class="info">.*?<span class="title">(?P<name>.*?)</span>'
                     r'.*?<p class="">(?P<director>.*?)&nbsp'
                     r'.*?<span class="rating_num" property="v:average">(?P<score>.*?)</span>'
                     r'.*?<span class="inq">(?P<quote>.*?)</span>', re.S)
for i in range(10):
    para['start'] = i * 25
    url = root + '?' + urlencode(para)
    resp = requests.get(url, headers=headers)
    for i in pattern.finditer(resp.text):
        writedata.append([i.group('name'), i.group('director').strip(), i.group('score'), i.group('quote')])
    resp.close()

# BeautifulSoup
writedata = []
for i in range(10):
    para['start'] = i * 25
    url = root + '?' + urlencode(para)
    resp = requests.get(url, headers=headers)
    # 生成bs对象
    bs = BeautifulSoup(resp.text, 'html.parser')
    # 从bs对象中查找数据
    items = bs.find_all(name='div', attrs={'class': 'info'})
    for item in items:
        name = item.find_all(name ='span', class_='title')[0].text
        director = item.find_all(name ='p', class_='')[0].text.strip()
        score = item.find_all(name='span', class_='rating_num')[0].text
        quote = item.find_all(name='span', class_='inq')
        if(quote == []):
            quote = ""
        else:
            quote = item.find_all(name='span', class_='inq')[0].text
        writedata.append([name, director, score, quote])
    resp.close()

# xpath
writedata = []
for i in range(10):
    para['start'] = i * 25
    url = root + '?' + urlencode(para)
    resp = requests.get(url, headers=headers)
    tree = etree.HTML(resp.text)
    for j in range(1, 26):
        name = tree.xpath(f'//*[@id="content"]/div/div[1]/ol/li[{j}]/div/div[2]/div[1]/a/span[1]/text()')[0]
        # 一次提取无法将导演信息准确提取出，需要利用正则表达式再提取一次
        message = tree.xpath(f'//*[@id="content"]/div/div[1]/ol/li[{j}]/div/div[2]/div[2]/p[1]/text()[1]')[0].strip()
        director = re.search(r'导演: (?P<director>.*?) ', message, re.S).group()
        score = tree.xpath(f'//*[@id="content"]/div/div[1]/ol/li[{j}]/div/div[2]/div[2]/div/span[2]/text()')[0]
        quote = tree.xpath(f'//*[@id="content"]/div/div[1]/ol/li[{j}]/div/div[2]/div[2]/p[2]/span/text()')
        if(quote == []):
            quote = ""
        else:
            quote = quote[0]
        writedata.append([name, director, score, quote])

    resp.close()

# 保存
with open('films.csv', 'w', newline="", encoding='utf-8') as f:
    csvwriter = csv.writer(f)
    csvwriter.writerow(['name', 'director', 'score', 'quote'])
    csvwriter.writerows(writedata)
f.close()
```
3种方法作比较，xpath是最简单的，在chrome中找到想要提取的元素后可以直接右键复制路径，不过可能需要正则表达式进行进一步处理；正则表达式写起来较为复杂，但是运行速度和效率都最高。
