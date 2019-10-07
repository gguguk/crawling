create_csv <- function(region, page, mode)
{
  dir_checker <-  dir.exists(file.path(getwd(), paste0("중부일보_", region)))
  
  if (mode == "final")
  {
    if(dir_checker)
    {
      write.csv(df, paste0(file.path(getwd(), paste0("중부일보_", region)), "/", region, "_최종", ".csv"), fileEncoding = "cp949")
    } else
    {
      dir.create(file.path(getwd(), paste0("중부일보_",region)))
      write.csv(df, paste0(file.path(getwd(), paste0("중부일보_", region)), "/", region, "_최종", ".csv"), fileEncoding = "cp949")
    }
  } else if(mode == "page")
  {
    if(dir_checker)
    {
      write.csv(df, paste0(file.path(getwd(), paste0("중부일보_", region)), "/", region, "_", page, ".csv"), fileEncoding = "cp949")
    } else
    {
      dir.create(file.path(getwd(), paste0("중부일보_",region)))
      write.csv(df, paste0(file.path(getwd(), paste0("중부일보_", region)), "/", region, "_", page, ".csv"), fileEncoding = "cp949")
    }  
  }
}

create_xlsx <- function(region, page, mode)
{
  dir_checker <-  dir.exists(file.path(getwd(), paste0("중부일보_", region)))
  
  if (mode == "final")
  {
    if(dir_checker)
    {
      write_xlsx(df, paste0(file.path(getwd(), paste0("중부일보_", region)), "/", region, "_최종", ".xlsx"))
    } else
    {
      dir.create(file.path(getwd(), paste0("중부일보_",region)))
      write_xlsx(df, paste0(file.path(getwd(), paste0("중부일보_", region)), "/", region, "_최종", ".xlsx"))
    }
  } else if(mode == "page")
  {
    if(dir_checker)
    {
      write_xlsx(df, paste0(file.path(getwd(), paste0("중부일보_", region)), "/", region, "_", page, ".xlsx"))
    } else
    {
      dir.create(file.path(getwd(), paste0("중부일보_",region)))
      write_xlsx(df, paste0(file.path(getwd(), paste0("중부일보_", region)), "/", region, "_", page, ".xlsx"))
    }  
  }
}