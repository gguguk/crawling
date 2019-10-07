create_csv <- function(region, page, mode, prefix)
{
  dir_checker <-  dir.exists(file.path(getwd(), paste0(prefix, "_", region)))
  
  if (mode == "final")
  {
    if(dir_checker)
    {
      write.csv(df, paste0(file.path(getwd(), paste0(prefix, "_", region)), "/", region, "_최종", ".csv"))
    } else
    {
      dir.create(file.path(getwd(), paste0(prefix, "_",region)))
      write.csv(df, paste0(file.path(getwd(), paste0(prefix, "_", region)), "/", region, "_최종", ".csv"))
    }
  } else if(mode == "page")
  {
    if(dir_checker)
    {
      write.csv(df, paste0(file.path(getwd(), paste0(prefix, "_", region)), "/", region, "_", page, ".csv"))
    } else
    {
      dir.create(file.path(getwd(), paste0(prefix, "_",region)))
      write.csv(df, paste0(file.path(getwd(), paste0(prefix, "_", region)), "/", region, "_", page, ".csv"))
    }  
  }
}

create_xlsx <- function(region, page, mode, prefix)
{
  dir_checker <-  dir.exists(file.path(getwd(), paste0(prefix, "_", region)))
  
  if (mode == "final")
  {
    if(dir_checker)
    {
      write_xlsx(df, paste0(file.path(getwd(), paste0(prefix, "_", region)), "/", region, "_최종", ".xlsx"))
    } else
    {
      dir.create(file.path(getwd(), paste0(prefix, "_",region)))
      write_xlsx(df, paste0(file.path(getwd(), paste0(prefix, "_", region)), "/", region, "_최종", ".xlsx"))
    }
  } else if(mode == "page")
  {
    if(dir_checker)
    {
      write_xlsx(df, paste0(file.path(getwd(), paste0(prefix, "_", region)), "/", region, "_", page, ".xlsx"))
    } else
    {
      dir.create(file.path(getwd(), paste0(prefix, "_",region)))
      write_xlsx(df, paste0(file.path(getwd(), paste0(prefix, "_", region)), "/", region, "_", page, ".xlsx"))
    }  
  }
}
