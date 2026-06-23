# ---- OPTRAM ----

#'---- Setup -----------
#'----------------------
# Install rOPTRAM package
if (!requireNamespace("rOPTRAM", quietly = TRUE)) {
  remotes::install_github("ropensci/rOPTRAM")
}
install.packages("neonUtilities")
# Load required packages
pkglist <- c("terra", "sf", "tmap", "CDSE", "rOPTRAM",
             "dplyr", "neonUtilities", "ggplot2", "lubridate")
invisible(lapply(pkglist, library, character.only = TRUE))

# ---- OPTRAM options ---- 

# 1. שמירת ההגדרות המקוריות של R (ליתר ביטחון)
original_opts <- options()
??optram_options
# 2. שינוי האפשרויות של rOPTRAM בהתאם לדרישות שלך
optram_options("only_vi_str", TRUE)
optram_options("veg_index", "SAVI")
optram_options("tileid", "12TUK") # שימוש באריח הספציפי שביקשת
optram_options("plot_colors", "months") 

# ---- Before Run ---- 
# parameters for Copernicus download
project_dir <- dirname("C:\\Users\\nitsa\\Desktop\\Uni\\RS_for_arid\\Arid_project")
Output_dir <- file.path(Project_dir, "Arid_project", "Output")
Download_dir <- file.path(Project_dir, "Arid_project", "Data")

dir.create(Download_dir, recursive = T, showWarnings = F)
dir.create(Output_dir, recursive = T, showWarnings = F)

aoi_file <- "C:\\Users\\nitsa\\Desktop\\Uni\\RS_for_arid\\Arid_project\\Reaserch Area\\new_aoi.gpkg"
from_date <- "2017-01-01"
to_date <- "2017-12-31"
max_cloud <- 20
creds_path <- "C:\\Users\\nitsa\\Desktop\\Uni\\RS_for_arid\\Arid_project\\rs-arid-regions-proj\\client _details_copernicus.txt" # Be sure this file is in .gitignore!
tile <- "12TUK" # To avoid multiple images from overlapping tiles
collection <- "sentinel-2-l2a"

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



rmse <- rOPTRAM::optram(
  aoi = aoi, 
  from_date = "2017-01-01", 
  to_date = "2017-12-31",
  #api_file = creds_path,
  S2_output_dir = Download_dir, # S2 images go to Data folder
  data_output_dir = Output_dir  # Final graphs, RDS, and rasters go to Output folder
)

# ---- Neon ----
# Parameters for NEON download
neon_site = "SRER"              # Sant Rita Experimental Range
neon_product <- "DP1.00094.001" # soil water content and salinity
timeIndex = 30                  # Only the 30 minute time interval


#'---- Acquire NEON data --
#'-------------------------

# Show sensor time intervals and 
# list of horizontal and vertical sensor locations at site
neonUtilities::getTimeIndex(dpID = neon_product)
neonUtilities::getHorVer(dpID = neon_product, site = neon_site)
# Download and filter data for a site
SM_data <- Acquire_Neon()
Plot_NEON_SoilMoisture(SM_data)
