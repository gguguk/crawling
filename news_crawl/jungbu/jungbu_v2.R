stime = Sys.time()

## working directory 설정
setwd("/media/caitech/b4490a4d-e98f-49e0-a636-b755f1430591/gyeongi_news_crawl")

## 패키지 및 커스텀 함수 불러오기
library(RSelenium)
library(rvest)
library(stringr)
library(data.table)
library(writexl)
source("tools.R", encoding = "UTF-8")

## 셀레니움 초기화
prefs = list("profile.managed_default_content_settings.images" = 2L)
cprof = list(chromeOptions = list(prefs = prefs))
ch = wdman::chrome(port=4567L)
driver = remoteDriver(port=4567L,
                      extraCapabilities = cprof,
                      browserName='chrome')
driver$open()
driver$maxWindowSize() # 창 크기d를 최대화.
driver$setImplicitWaitTimeout(10000)

## 지역 코드를 초기화 함.
# 중부일보 지역 코드.
j.codes = 36:66
names(j.codes) = c("가평군", "고양시", "과천시", "광명시", "광주시", "구리시", "군포시", "김포시", "남양주시", "동두천시", "부천시", "성남시", "수원시", "시흥시", "안산시", "안성시", "안양시", "양주시", "양평군", "여주시", "연천군", "오산시", "용인시", "의왕시", "의정부시", "이천시", "파주시", "평택시", "포천시", "하남시", "화성시")

# key값으로 사용할 지역명 초기화.
regions = c("가평군", "고양시", "과천시", "광명시", "광주시", "구리시", "군포시", "김포시", "남양주시", "동두천시", "부천시", "성남시", "수원시", "시흥시", "안산시", "안성시", "안양시", "양주시", "양평군", "여주시", "연천군", "오산시", "용인시", "의왕시", "의정부시", "이천시", "파주시", "평택시", "포천시", "하남시", "화성시")

## 중부일보 크롤링
for(region in regions)
{
  df = data.frame()
  url = paste0("http://www.joongboo.com/news/articleList.html?page=1&total=&sc_section_code=S1N6&sc_sub_section_code=S2N", j.codes[region], "&sc_serial_code=&sc_area=&sc_level=&sc_article_type=&sc_view_level=&sc_sdate=2017-01-01&sc_edate=2018-10-31&sc_serial_number=&sc_word=")
  
  while(TRUE)
  {
    try(expr={
      driver$navigate(url)
      driver$findElement("css selector", ".article-list-content.text-left")
      break
    })
    Sys.sleep(2)
  }
  source = driver$getPageSource()[[1]]
  html = source %>% read_html()
  
  max_page = ceiling(as.numeric(html %>% html_node(".text-muted") %>% html_text() %>% str_remove(",") %>% str_extract("[0-9]+")) / 20)
  
  writeLines(sprintf("[중부일보-%s] 전체 %s 페이지입니다. 크롤링을 시작합니다.", region, max_page))
  
  ####
  
  page = 1
  
  ####
  
  while(TRUE) # 페이지를 순회하며 크롤링 시작.
  {
    if(page != 1)
    {
      while(TRUE)
      {
        try(expr={
          driver$navigate(paste0("http://www.joongboo.com/news/articleList.html?page=", page, "&total=&sc_section_code=S1N6&sc_sub_section_code=S2N", j.codes[region], "&sc_serial_code=&sc_area=&sc_level=&sc_article_type=&sc_view_level=&sc_sdate=2017-01-01&sc_edate=2018-10-31&sc_serial_number=&sc_word="))  
          driver$findElement("css selector", ".table-row > .list-dated.table-cell")
          break
        })
        Sys.sleep(1)
      }
      source = driver$getPageSource()[[1]]
      html = source %>% read_html()
    }
    
    titles = html %>% html_nodes(".links > strong") %>% html_text() %>% as.character()
    
    fil_idx = !str_detect(titles, "화보")
    
    titles = titles[fil_idx]
    
    dates = html %>% html_nodes(".table-row > .list-dated.table-cell") %>% html_text() %>% str_split(" \\| | ") %>% lapply(function(x) x[2]) %>% unlist() %>% as.character()
    dates = dates[fil_idx]
    
    context_urls = html %>% html_nodes(".table-row .links") %>% html_attr("href")
    context_urls = paste0("http://www.joongboo.com", context_urls) %>% as.character()
    
    contexts = c() 
    for(i in 1:length(context_urls)) # context_urls를 바탕으로 기사 내용 크롤링
    {
      while(TRUE)
      {
        try(expr={
          driver$navigate(context_urls[i])
          driver$findElement("css selector", "div#article-view-content-div")
          break
        })
        Sys.sleep(1)
      }
      driver$executeScript("$('p:empty()').remove()") # 비어있는 p태그를 삭제함.
      driver$executeScript("$('p').each(function() {var $this = $(this); if($this.html() == '&nbsp;') $this.remove(); });") # &nbsp;(공백)이 있는 p태그는 제거한다.
      
      source = driver$getPageSource()[[1]]
      html = source %>% read_html()
      
      context_checker <- html %>% html_nodes("div#article-view-content-div > p")
      
      if (length(context_checker) == 0) # 기사내용이 p태그로 감싸져있지 않고 div#article-view-content-div에 직접적으로 있는 경우. 그러나 한번씩 기자이름만 p태그에 걸려있는 경우가 있어서 조건 추가.
      {
        cur_context = driver$executeScript("return $('#article-view-content-div').contents().not($('#article-view-content-div').children()).text()", args=list('empty'))[[1]] %>% str_remove_all("\n{0,}\t{0,}") %>% str_trim("both")
      } else if(length(context_checker) <= 2) # 가장 흔한경우. 첫번째 p태그엔 뉴스내용, 2번째 p태그에는 기자 이름.
      {
        cur_context = context_checker[1] %>% html_text(trim=T) %>% str_replace_all("(\\n)+ {0,}", " ")
      } else # 기사 내용이 여러 p 태그에 감싸져 있는 경우 
      {
        cur_context = paste0(head(context_checker %>% html_text(trim=T) %>% str_replace_all("(\\n)+ {0,}", " "), -1), collapse=" ") %>% str_trim("both")
      }
      
      contexts = as.character(c(contexts, cur_context))
      
      writeLines(sprintf("%s(/%s) 페이지: %s(/%s)번째 기사의 내용을 크롤링 하였습니다.", page, max_page, i, length(context_urls)))
      
      # Sys.sleep(runif(1, 1, 3))
      
    }
    
    cur_df = data.frame(지역=region, 
                          제목=titles, 
                          날짜=dates, 
                          내용=contexts, 
                          URL=context_urls, 
                          신문사="중부일보",
                          stringsAsFactors = F)
    
    df = rbindlist(list(df, cur_df))
    
    create_xlsx(region, page, mode="page") # 지역과 페이지 번호를 이용하여 현재까지의 df 객체를 csv파일로 저장.
    
    message(sprintf("[중부일보-%s] %s(/%s)번째 페이지까지 완료 하였습니다.", region, page, max_page))
    
    if(page == max_page) break
    page = page + 1
  }
  
  message(sprintf("[중부일보-%s] 크롤링을 완료하였습니다. 저장하고 다음 지역으로 넘어갑니다...", region))
  create_xlsx(region, page, mode="final")
  
  Sys.sleep(30)
  
}

writeLines(sprintf("크롤링 총 소요시간은 %0.3f입니다.", Sys.time()-stime))