Get_CDSE_Token <- function(creds_path) {
  # Prepare an API token to access Copernicus Dataspace.
  # creds_path is the full path to a csv file containing clientid and secret
  # The file should be formatted as:
  # clientid,secret
  # sh-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  # Return the token
  
  creds <- read.csv(creds_path)
  # What if file does not exist??
  clientid <- creds$clientid
  secret <- creds$secret
  tok <- CDSE::GetOAuthToken(id = clientid, secret = secret)
  return(tok)
}

Get_CDSE_ImageList <- function(aoi, token, max_cloud, tile) {
  # Call the CDSE function that lists all available images for a date range
  # Return a list of suitable images
  img_list <- CDSE::SearchCatalog(aoi = aoi,
                                  from = from_date, to = to_date,
                                  collection = "sentinel-2-l2a",
                                  token = token)
  img_list <- img_list |>
    dplyr::filter(tileCloudCover <= max_cloud) |>
    dplyr::filter(grepl(pattern = tile, x = sourceId))
  message("Found: ", nrow(img_list), " images.")
  return(img_list)
}

Acquire_Images <- function(img_list, aoi, token ) {
  # Download the images from img_list, and prepare water surface raster
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
    # Save tiff to output directory
    return(img) # Improve to return image file name, not full image
  }) 
  return(dl_list)
}

Plot_Image <- function(img) {
  tmap::tmap_mode("plot")
  tm <- tm_basemap() +
    tm_shape(img) +
    tm_raster() +
    tm_scalebar(breaks = c(0, 5, 10), text.size = 1)
  return(tm)
}

Build_rOPTRAM <- function(from_date, to_date) {

  return(coeffs)  
}

Prepare_Soil_Moisture <- function(coeffs, img_date) {
  
  return(SM_raster)
}
