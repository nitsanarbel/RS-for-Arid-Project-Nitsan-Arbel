Get_CDSE_Token <- function(creds_path) {
  # Prepare an API token to access Copernicus Dataspace.
  # --------------------------------------------------------------
  creds <- read.csv(creds_path)
  clientid <- creds$clientid
  secret <- creds$secret
  tok <- CDSE::GetOAuthToken(id = clientid, secret = secret)
  return(tok)
}

Get_CDSE_ImageList <- function(aoi, token, max_cloud, tile) {
  # Call the CDSE function that lists all available images for a date range
  # Return a list of suitable images
  # --------------------------------------------------------------
  img_list <- CDSE::SearchCatalog(aoi,
                                  from = from_date, to = to_date,
                                  collection = collection,
                                  token = token)
  img_list <- img_list |>
    dplyr::filter(tileCloudCover <= max_cloud) |>
    dplyr::filter(grepl(pattern = tile, x = sourceId))
  message("Found: ", nrow(img_list), " images.")
  return(img_list)
}

Acquire_Images <- function(img_list, aoi, token) {
  # Download the images from img_list, and prepare water surface raster
  # --------------------------------------------------------------
  dl_list <- lapply(1:nrow(img_list), function(x) {
    img_date <- img_list$acquisitionDate[x]
    img <- CDSE::GetImage(aoi = aoi,
                          time_range = img_date,
                          collection = "sentinel-2-l2a",
                          script = "MNDWI.js",
                          resolution = 20,
                          token = token,
                          format = "image/tiff",
                          mask = TRUE)
    names(img) <- paste0("MNDWI_", as.character(img_date))
    return(img)
  }) 
  return(dl_list)
}

Plot_Image <- function(img) {
  tmap::tmap_mode("plot")
  tm <- tmap::tm_basemap() +
    tm_shape(img) +
    tm_raster() +
    tm_scalebar(breaks = c(0, 5, 10), text.size = 1)
  return(tm)
}

Build_rOPTRAM <- function(from_date, to_date) {
  # Call the rOPTRAM wrapper function
  # --------------------------------------------------------------
  creds <- read.csv(creds_path)
  clientid <- creds$clientid
  secret <- creds$secret
  rOPTRAM::store_cdse_credentials(clientid, secret)
  return(coeffs)  
}

Prepare_OPTRAM_SoilMoisture <- function(coeffs, img_date) {
  return(SM_raster)
}

Compare_Multiyear <- function(VI_STR_df, yr1, yr2) {
  # Load a multiyear data.frame of VI and STR values
  # Split out values from two individual years and compare them
  # --------------------------------------------------------------
  str(VI_STR_df)
  unique(lubridate::year(VI_STR_df$TimestampUTC))
  nrow(VI_STR_df)
  
  VI_STR_yr1 <- VI_STR_df[lubridate::year(VI_STR_df$TimestampUTC) == yr1,]
  VI_STR_yr2 <- VI_STR_df[lubridate::year(VI_STR_df$TimestampUTC) == yr2,]
  message("Individual year data rows: ", nrow(VI_STR_yr1), " and ", nrow(VI_STR_yr2))
  
  Plot_Year <- function(df) {
    yr <- lubridate::year(df$TimestampUTC)
    pl <- ggplot(df) + 
      geom_point(aes(x = VI, y = STR), color = "blue", alpha = 0.2) +
      theme_bw() +
      ggtitle(paste("Scatterplot for ", yr))
    print(pl)
  }
  Plot_Year(VI_STR_yr1)
  Plot_Year(VI_STR_yr2)
}