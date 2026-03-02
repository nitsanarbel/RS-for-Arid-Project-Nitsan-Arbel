#'---- Setup -----------
#'----------------------
# Install rOPTRAM package
remotes::install_github("ropensci/rOPTRAM")
# Load required packages
pkglist <- c("terra", "sf", "tmap", "CDSE", "rOPTRAM", "dplyr")
invisible(lapply(pkglist, library, character.only = TRUE))

Output_dir <- "Output"
aoi_file <- "aoi.gpkg"
from_date <- "2025-12-01"
to_date <- "2026-03-15"
max_cloud <- 15
creds_path <- "cdse_credentials.txt" # Be sure this file is in .gitignore!
tile <- "36JWT" # To avoid multiple images from overlapping tiles

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