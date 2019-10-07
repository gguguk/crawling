## set parameters
query="프릳츠"

num_scroll = 500

## set working directory
setwd("/home/caitech/ku_lab/juwon")

## 패키지 및 커스텀 함수 불러오기
library(RSelenium)
library(wdman)
library(rvest)
library(stringr)
library(data.table)
library(writexl)

## 셀레니움 초기화
# args = list("--user-agent='Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25'",
#             "--disalbe-gpu",
#             "--headless")
# prefs = list("profile.managed_default_content_settings.images"=2L, 
#              "disk-cache-size"=4096L)
# cprof = list(chromeOptions = list(args=args, prefs = prefs))
# ch = chrome(port=4567L)
# driver = remoteDriver(port=4567L,
#                       extraCapabilities = cprof,
#                       browserName='chrome')

prefs = list("profile.managed_default_content_settings.images"=2L, 
             "disk-cache-size"=4096L)
cprof = list(chromeOptions = list(prefs = prefs))
ch = chrome(port=1478L)
driver = remoteDriver(port=1478L,
                      extraCapabilities = cprof,
                      browserName='chrome')
driver$open()
driver$maxWindowSize() # 창 크기d를 최대화.
driver$setImplicitWaitTimeout(10000)
os = Sys.info()["sysname"]
if(os=="Windows")
{
  driver$navigate(paste0("https://www.instagram.com/explore/tags/", query, "/?hl=ko"))  
} else
{
  driver$navigate(paste0("https://www.instagram.com/explore/tags/", URLencode(query), "/?hl=ko"))  
}

res = c() # create empty dataframe to save result

stime = Sys.time() # set code start time

prev_url = ""
for(i in 1:num_scroll) # execute urls scraping
{
  body = driver$findElement("css selector", "body") # for page scroll down
  
  body$sendKeysToElement(list(key="end")) # execute page scroll
  
  Sys.sleep(1.5)
  
  source = driver$getPageSource()[[1]] # get current page source
  
  html = source %>% read_html() # get parsed html page
  
  urls = paste0("https://www.instagram.com", html %>% html_nodes(xpath="//*[@class='KL4Bh']/parent::*/parent::*") %>% html_attr("href"))
  
  if(prev_url == tail(urls, 1)) {print("중복 정보가 수집되었으므로 다음으로 넘어갑니다.") ; break}
  
  res = c(res, urls)
  
  prev_url = tail(urls, 1)
  
  writeLines(sprintf("%s(/%s)번 스크롤링 하였습니다. (%s)", i, num_scroll, tail(urls, 1)))
}

message("각 피드의 URL 수집을 완료하였습니다. 이제 각 피드를 순회하며 내용을 스크래핑합니다...")

ures = unique(res)

texts = c()

for(i in 1:length(ures))
{
  driver$navigate(ures[i])
  
  # text = driver$executeScript("return document.querySelector('.C4VMK > span').textContent") %>% unlist()
  
  source = driver$getPageSource()[[1]]
  
  html = source %>% read_html()
  
  text = html %>% html_node(".C4VMK > span") %>% html_text(trim=T)
  
  texts = c(texts, text)
  
  sleep = runif(1, 2, 6)
  
  writeLines(sprintf("%s(/%s)번째까지 완료하였습니다. (sleep %0.2f초)", i, length(ures), sleep))
  
  Sys.sleep(sleep) # random slepp
}

writeLines(sprintf("크롤링 총 소요시간은 %0.3f분입니다.", Sys.time()-stime))

result_df = data.frame(texts=texts, urls=ures, stringsAsFactors = F)

write_xlsx(result_df, "result.xlsx")

driver$close()

word_vec = unlist(str_extract_all(result_df$texts, "(?<=#)\\w+"))

word_vec = word_vec[word_vec != "프릳츠"]

sorted_word = sort(table(word_vec), decreasing = T)

write_xlsx(data.frame(rank=1:length(sorted_word),
                      word=names(sorted_word), 
                      count=as.numeric(sorted_word)), 
           "fritz.xlsx")
