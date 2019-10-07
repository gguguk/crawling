from bs4 import BeautifulSoup as bs, NavigableString, Comment
import requests
import re
import pandas as pd
import time
import os
import math

# 검색할 문자를 지정한다.
# query = "타다"
query = ["택시 타다", "택시 카풀", "택시 풀러스", "택시 분신", "모빌리티플랫폼", "택시 요금인상", "택시 승차거부", "택시 불만", "택시 집회", "택시 시위", "카카오 카풀", "타다 이재웅"]

# 데이터 수집 기간을 지정한다.
date_range = pd.date_range(start='20180601', end='20190601')
date1 = date_range.strftime("%Y.%m.%d").tolist()
date2 = date_range.strftime("%Y%m%d").tolist()

# 네이버 뉴스로 연결되는 신문사만 선택한 후 쿠키에 심는다.
cookies = {'news_office_checked': '1032,1005,1020,1021,1081,1022,1023,1025,1028,1469,1421,1003,1001,1422,1449,1004,1437,1056,1214,1019,1055,1374,1448,1052,1138,1029,1009,1008,1293,1011,1277,1018,1030,1366,1123,1014,1015,1016,1092,1079,1119,1417,1006,1031,1047,1002,1087,1088,1082,2205,1024,1308,1586,1262,1094,1243,1033,1037,1053,1353,1036,1050,1127,1607,1584,1310,1007,1152,1044,1296,1346'}

for q in query:
    # 크롤링을 진행한다.
    all_category = []
    all_titles = []
    all_contents = []
    all_presses = []
    all_dates = []
    all_hrefs = []

    for i, (d1, d2) in enumerate(zip(date1, date2)):
        stime = time.time()
        # 날짜 별로 url을 달리하여 파싱한다
        url = "https://search.naver.com/search.naver?&where=news&query={0}&sm=tab_pge&sort=0&photo=0&field=0&reporter_article=&pd=3&ds={1}&de={1}&docid=&nso=so:r,p:from{2}to{2},a:all&mynews=1&cluster_rank=70&start=1&refresh_start=0".format(q, d1, d2)
        res = requests.get(url, cookies=cookies) ; assert res.ok, "서버의 응답이 정상적이지 않습니다."
        html = res.text
        soup = bs(html, "html.parser")

        # 페이지 개수를 찾는다. 만일 검색 기록이 없으면 다음 날짜로 넘어간다.
        page_tag = soup.select_one("div.title_desc.all_my span")
        if page_tag != None:
            num_pages = re.sub(",", "", page_tag.text) # 페이지 수가 4자리 이상이면 콤마(,)가 찍혀서 연속된 숫자를 얻을 수 없다. 따라서 콤마를 없애준다.(콤마가 애초에 없을 경우는 identity 함수처럼 작동한다.)
            num_pages = math.ceil(int(re.search("(?=\d+건)\d+", num_pages).group()) / 10)
        else:
            continue

        cur_titles, cur_presses, cur_dates, cur_hrefs = [], [], [], []
        # 특정 날짜의 페이지를 순회하면서 크롤링을 진행한다.
        for j in range(num_pages):
            
            # 첫번째 페이지는 이미 페이지 개수를 찾기 위해서 접속 했으므로 다시 접속하는 불필요한 행위를 할 필요가 없다.
            if j != 0:
                url = "https://search.naver.com/search.naver?&where=news&query={0}&sm=tab_pge&sort=0&photo=0&field=0&reporter_article=&pd=3&ds={1}&de={1}&docid=&nso=so:r,p:from{2}to{2},a:all&mynews=1&cluster_rank=70&start={3}&refresh_start=0".format(q, d1, d2, (i*10) + 1)
                res = requests.get(url, cookies=cookies) ; assert res.ok, "서버의 응답이 정상적이지 않습니다."
                html = res.text
                soup = bs(html, "html.parser")

            titles = [tag['title'].strip() for tag in soup.select("ul.type01 > li > dl > dt > a._sp_each_title")] # text 메소드를 사용하면 제목이 길 경우 짤릴 수 있으므로 'text' 속성에 있는 값을 가져온다.
            presses = [tag.contents[0] for tag in soup.select("ul.type01 > li > dl > dd.txt_inline > span._sp_each_source")]
            dates = [re.search("\d+\.\d+\.\d+\.", tag.text).group(0) for tag in soup.select("ul.type01 > li > dl > dd.txt_inline")]
            hrefs = [tag['href'] for tag in soup.select("ul.type01 > li > dl > dd.txt_inline > a._sp_each_url")]
            assert len(titles) == len(presses) == len(dates) == len(hrefs), "수집된 데이터의 길이가 다릅니다."

            relation_titles = [tag['title'].strip() for tag in soup.select("ul.relation_lst > li > a")]
            relation_presses = [tag.text.strip() for tag in soup.select("ul.relation_lst > li > span.txt_sinfo > span.press")]
            relation_dates = [re.search("\d+\.\d+\.\d+\.", tag.text).group(0) for tag in soup.select("ul.relation_lst > li > span.txt_sinfo")]
            relation_hrefs = [tag['href'] for tag in soup.select("ul.relation_lst > li > span.txt_sinfo > a._sp_each_url")]
            assert len(relation_titles) == len(relation_presses) == len(relation_dates) == len(relation_hrefs), "수집된 데이터의 길이가 다릅니다."

            cur_titles = titles + relation_titles ; all_titles.extend(cur_titles)
            cur_presses = presses + relation_presses ; all_presses.extend(cur_presses)
            cur_dates = dates + relation_dates ; all_dates.extend(cur_dates)
            cur_hrefs = hrefs + relation_hrefs ; all_hrefs.extend(cur_hrefs)
            assert len(cur_titles) == len(cur_presses) == len(cur_dates) == len(cur_hrefs), "수집된 데이터의 길이가 다릅니다."

            # 현재 페이지의 뉴스 링크를 순회하면서 카테고리와 내용을 가져온다.
            cur_contents, cur_category = [], []
            for k, href in enumerate(cur_hrefs):
                res2 = requests.get(href)
                html2 = res2.text
                soup2 = bs(html2, "html.parser")

                # 텍스트를 추출하는데 방해가 되는 script 및 style 태그를 모두 삭제한다.
                for script in soup2(["script", "style"]):                   
                    script.decompose()  

                # 뉴스 내용과 카테고리를 가져온다.
                # strong, a, span 등의 태그로 감싸져있는 텍스트를 제외하고 순수하게 div#articleBodyContents 바로 밑에 있는 텍스트들만 가져온다.
                # 이를 통해서 최대한 정제된 텍스트를 가져올 수 있음. 예를 들어서 광고등을 어느정도 걸러낼 수 있음.
                
                # 1) 뉴스가 '속보' 탭에 있을 경우... 
                content = soup2.select_one(".article") 
                if content != None:
                    content = " ".join([ele.strip() for ele in content.children if isinstance(ele, NavigableString) and not isinstance(ele, Comment)]).strip()
                else:
                # 2) 뉴스가 '연예', '스포츠', '속보'를 제외한 탭에 있을 경우
                    content = soup2.select_one("div#articleBodyContents") # 연예, 스포츠를 제외한 뉴스 기사는 div#articleBodyContents를 통해서 추출할 수 있음
                    if content != None:
                        content = " ".join([ele.strip() for ele in content.children if isinstance(ele, NavigableString) and not isinstance(ele, Comment)]).strip()
                    else:
                        content = ""

                categories = soup2.select("em.guide_categorization_item")
                if len(categories) == 1:
                    category = categories[0].text.strip()
                elif len(categories) >= 2:
                    category = ", ".join([tag.text for tag in categories])
                else:
                    category = ""

                # 현재 페이지의 뉴스 내용과 카테고리를 한데 모은다
                cur_contents.append(content)
                cur_category.append(category)
            assert len(cur_hrefs) == len(cur_contents) == len(cur_category), "수집된 데이터의 길이가 다릅니다."

            # 페이지당 뉴스 내용과 카테고리를 한데 모은다.
            all_contents.extend(cur_contents)
            all_category.extend(cur_category)

        print("[{}] {}({}/{})까지 완료하였습니다......{:.2f}초".format(q, d1, i+1, len(date1), time.time() - stime))
        time.sleep(0.5)

        if (i+1) % 50 == 0:
            sub_df = pd.DataFrame(data={'category': all_category, 'titles': all_titles, 'contents': all_contents, 'presses': all_presses, 'dates': all_dates, 'hrefs': all_hrefs})
            sub_df.to_excel("naver_news_{}_{}.xlsx".format(q, i))

    result_df = pd.DataFrame(data={'category': all_category, 'titles': all_titles, 'contents': all_contents, 'presses': all_presses, 'dates': all_dates, 'hrefs': all_hrefs})
    result_df.to_excel("naver_news_{}.xlsx".format(q))

