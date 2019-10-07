from bs4 import BeautifulSoup as bs
import requests
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.firefox_binary import FirefoxBinary

import time
import pandas as pd

# 검색어를 입력한다.
query = ["택시 타다", "모빌리티플랫폼"]

# geckodriver의 위치를 결정한다.
gecko_path = "/home/caitech/Downloads/geckodriver"

# 이미지 로딩을 막는 프로파일을 설정한다
firefox_profile = webdriver.FirefoxProfile()
firefox_profile.set_preference('permissions.default.image', 2)
firefox_profile.set_preference('dom.ipc.plugins.enabled.libflashplayer.so', 'false')

# 파이어폭스 브라우저를 켜고 창 크기를 최대화 한다.
# driver = webdriver.Firefox(executable_path=gecko_path, firefox_profile=firefox_profile)
# driver.maximize_window()

for q in query:
    driver = webdriver.Firefox(executable_path=gecko_path, firefox_profile=firefox_profile)
    driver.maximize_window()
    driver.get("https://twitter.com/search?f=tweets&vertical=default&q={}%20since%3A2018-06-01%20until%3A2019-06-01&src=typd&lang=ko".format(q))

    # 마지막 페이지까지 로드할 수 있도록 스크롤링을 진행한다.
    while True:
        elemsCount = driver.execute_script("return document.querySelectorAll('.stream-items > li.stream-item').length")
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(0.5)
        try:
            WebDriverWait(driver, 20).until(
                lambda x: x.find_element_by_xpath(
                    "//*[contains(@class,'stream-items')]/li[contains(@class,'stream-item')]["+str(elemsCount+1)+"]"))
        except:
            print("마지막 페이지에 도달하였습니다.")
            break
            
    id_tags = driver.find_elements_by_css_selector("div.stream-item-header > a > span.username.u-dir.u-textTruncate > b")
    date_tags = driver.find_elements_by_css_selector("span._timestamp")
    content_tags = driver.find_elements_by_css_selector("p.TweetTextSize")
    href_tags = driver.find_elements_by_css_selector("div.js-original-tweet")
    
    ids = [item.text.strip() for item in id_tags]
    dates = [item.text.strip() for item in date_tags]
    contents = [item.text.strip() for item in content_tags]
    hrefs = ['https://twitter.com' + item.get_attribute('data-permalink-path') for item in href_tags]
    
    df = pd.DataFrame(data={'ids': ids, 'dates': dates, 'contents': contents, 'links': hrefs, 'query': q})
    df.to_excel("twitter_{}.xlsx".format(q))