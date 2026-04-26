#'---- Setup -----------
#'----------------------
# Install rOPTRAM package
remotes::install_github("ropensci/rOPTRAM")
install.packages("neonUtilities")
# Load required packages
pkglist <- c("terra", "sf", "tmap", "CDSE", "rOPTRAM",
             "dplyr", "neonUtilities", "ggplot2")
invisible(lapply(pkglist, library, character.only = TRUE))

# parameters for Copernicus download
Project_dir <- dirname(getwd())
Output_dir <- file.path(Project_dir, "Output")
Download_dir <- file.path(Project_dir, "Data")
aoi_file <- "aoi.gpkg"
from_date <- "2025-12-01"
to_date <- "2026-03-15"
max_cloud <- 15
creds_path <- "cdse_credentials.txt" # Be sure this file is in .gitignore!
tile <- "36JWT" # To avoid multiple images from overlapping tiles
collection <- "sentinel-2-l2a"

# Parameters for NEON download
neon_site = "SRER"              # Sant Rita Experimental Range
neon_product <- "DP1.00094.001" # soil water content and salinity
timeIndex = 30                  # Only the 30 minute time interval

#'---- Acquire images -----
#'-------------------------
aoi <- sf::st_read(aoi_file)
token <- Get_CDSE_Token(creds_path)
# Show available collections:
CDSE::GetCollections()
img_list <- Get_CDSE_ImageList(aoi = aoi, token = token, max_cloud, tile)

imgs <- Acquire_Images(img_list, aoi, token)

p1 <- Plot_Image(imgs[[1]])
p2 <- Plot_Image(imgs[[length(imgs)]])
p1
p2

#'---- Acquire NEON data --
#'-------------------------

# Show sensor time intervals and 
# list of horizontal and vertical sensor locations at site
neonUtilities::getTimeIndex(dpID = neon_product)
neonUtilities::getHorVer(dpID = neon_product, site = neon_site)
# Download and filter data for a site
SM_data <- Acquire_Neon()
Plot_NEON_SoilMoisture(SM_data)
