# Install rOPTRAM package
remotes::install_github("ropensci/rOPTRAM")
# Load required packages
pkglist <- c("terra", "sf", "tmap", "rOPTRAM")
invisible(lapply(pkglist, library, character.only = TRUE))
