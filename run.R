#'---- Setup -----------
# Load required packages
pkglist <- c("terra", "sf", "tmap", "CDSE", "rOPTRAM",
             "dplyr", "ggplot2", "lubridate", "stringr")
invisible(lapply(pkglist, library, character.only = TRUE))
source("functions.R")

# Parameters for Copernicus download and directories
Project_dir  <- dirname(getwd())
Output_dir   <- file.path(Project_dir, "Output")
Download_dir <- file.path(Project_dir, "Data")

aoi_file   <- "C:/Users/nitsa/Desktop/Uni/RS_for_arid/Arid_project/Reaserch Area/new_aoi.gpkg"
from_date  <- "2025-01-01"
to_date    <- "2025-12-31"
max_cloud  <- 20
creds_path <- "C:/Users/nitsa/Desktop/Uni/RS_for_arid/Arid_project/rs-arid-regions-proj/client_details_copernicus.txt"
tile       <- "12TUK"
collection <- "sentinel-2-l2a"

#---- Optram Options ----
optram_options("only_vi_str", TRUE)
optram_options("veg_index", "SAVI")
optram_options("tileid", "12TUK")
optram_options("plot_colors", "months")
optram_options("overwrite", TRUE)

#---- Acquire images -----
aoi   <- sf::st_read(aoi_file)
token <- Get_CDSE_Token(creds_path)
img_list <- Get_CDSE_ImageList(aoi = aoi, token = token, max_cloud, tile)
imgs     <- Acquire_Images(img_list, aoi, token)

p1 <- Plot_Image(imgs[[1]])
p2 <- Plot_Image(imgs[[length(imgs)]])
p1
p2

#---- OPTRAM Model Execution ----
# עבור כל שנה שונו התאריכים לפני כל הרצה
rmse <- optram(
  aoi             = aoi, 
  from_date       = "2025-01-01", 
  to_date         = "2025-12-31",
  S2_output_dir   = Download_dir,
  data_output_dir = Output_dir
)

#---- All Years Trapezoid Plots (2017-2025) ----
base_output_dir <- Output_dir
years           <- 2017:2025
plot_list       <- list()

for (yr in years) {
  rds_path  <- file.path(base_output_dir, as.character(yr), "VI_STR_data.rds")
  edge_path <- file.path(base_output_dir, as.character(yr), "trapezoid_edges_lin.csv")
  
  if (file.exists(rds_path) && file.exists(edge_path)) {
    full_df  <- readRDS(rds_path)
    edges_df <- read.csv(edge_path)
    
    p <- plot_vi_str_cloud(full_df, edges_df)
    p <- p + 
      ggtitle(paste("Trapezoid plot for AOI -", yr)) +
      theme_minimal() +
      theme(
        plot.title      = element_text(face = "bold", size = 13, hjust = 0.5),
        legend.position = "right"
      )
    
    save_path <- file.path(base_output_dir, as.character(yr), paste0("trapezoid_plot_", yr, ".png"))
    ggsave(save_path, plot = p, width = 8, height = 6, dpi = 300)
    
    plot_list[[as.character(yr)]] <- p
    message(paste("Successfully created and saved trapezoid plot for:", yr))
  } else {
    warning(paste("Missing files for year:", yr, "- skipping."))
  }
}

#---- Trajectories and Extents (2017-2025) ----
month_levels      <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
extent_records    <- list()
all_monthly_means <- list()

for (yr in years) {
  rds_path <- file.path(base_output_dir, as.character(yr), "VI_STR_data.rds")
  
  if (file.exists(rds_path)) {
    full_df <- readRDS(rds_path)
    
    # חילוץ חודש מעמודת TimestampUTC
    full_df$Month_Num <- as.numeric(substr(as.character(full_df$TimestampUTC), 6, 7))
    full_df$Month     <- factor(month.abb[full_df$Month_Num], levels = month_levels)
    full_df           <- full_df %>% filter(!is.na(Month) & !is.na(VI) & !is.na(STR))
    
    # חישוב ממוצעים חודשיים
    monthly_summary <- full_df %>%
      group_by(Month, Month_Num) %>%
      summarise(
        SAVI = mean(VI, na.rm = TRUE),
        STR  = mean(STR, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      arrange(Month_Num) %>%
      mutate(Year = yr)
    
    all_monthly_means[[as.character(yr)]] <- monthly_summary
    
    # דיגום פיקסלים לרקע
    plot_bg <- sample_n(full_df, min(20000, nrow(full_df)))
    
    # 1. גרף Trajectory (SAVI מ-0 עד 0.3)
    p_traj <- ggplot() +
      geom_point(data = plot_bg, aes(x = VI, y = STR, color = Month), alpha = 0.15, size = 0.6, show.legend = FALSE) +
      geom_path(data = monthly_summary, aes(x = SAVI, y = STR, linetype = "Monthly trajectory"), color = "black", linewidth = 0.85) +
      geom_point(data = monthly_summary, aes(x = SAVI, y = STR, fill = Month), shape = 21, color = "black", size = 3.8, stroke = 0.8) +
      scale_fill_viridis_d(option = "turbo", name = "Month", drop = FALSE) +
      scale_color_viridis_d(option = "turbo", drop = FALSE) +
      scale_linetype_manual(name = "", values = c("Monthly trajectory" = "solid")) +
      coord_cartesian(xlim = c(0, 0.3), ylim = c(0, 2)) +
      labs(title = paste("OPTRAM Trajectory -", yr), x = "SAVI", y = "STR") +
      theme_classic() +
      theme(
        plot.title      = element_text(face = "bold", size = 13, hjust = 0.5),
        axis.title      = element_text(face = "bold", size = 11),
        axis.text       = element_text(color = "black", size = 10),
        panel.border    = element_rect(color = "black", fill = NA, linewidth = 0.8),
        legend.position = "right"
      ) +
      guides(
        fill     = guide_legend(order = 1, override.aes = list(size = 3.5, shape = 21, color = "black")),
        linetype = guide_legend(order = 2)
      )
    
    ggsave(file.path(base_output_dir, as.character(yr), paste0("trajectory_optram_", yr, ".png")),
           plot = p_traj, width = 7.5, height = 5.5, dpi = 300)
    
    # 2. חישוב וגרף Extent
    dry_row <- monthly_summary[which.max(monthly_summary$STR), ]
    wet_row <- monthly_summary[which.min(monthly_summary$STR), ]
    
    dx <- dry_row$SAVI[1] - wet_row$SAVI[1]
    dy <- dry_row$STR[1]  - wet_row$STR[1]
    length_vec <- sqrt(dx^2 + dy^2)
    angle_deg  <- atan2(abs(dy), abs(dx)) * (180 / pi)
    
    extent_records[[as.character(yr)]] <- data.frame(
      Year      = yr,
      Dry_Month = as.character(dry_row$Month[1]),
      Dry_SAVI  = dry_row$SAVI[1],
      Dry_STR   = dry_row$STR[1],
      Wet_Month = as.character(wet_row$Month[1]),
      Wet_SAVI  = wet_row$SAVI[1],
      Wet_STR   = wet_row$STR[1],
      Length    = length_vec,
      Angle_deg = angle_deg,
      stringsAsFactors = FALSE
    )
    
    extent_pts <- rbind(
      data.frame(dry_row, Condition = paste0("Dry (", dry_row$Month[1], ")")),
      data.frame(wet_row, Condition = paste0("Wet (", wet_row$Month[1], ")"))
    )
    
    p_ext <- ggplot() +
      geom_point(data = plot_bg, aes(x = VI, y = STR), color = "grey82", alpha = 0.15, size = 0.5) +
      geom_segment(
        aes(x = wet_row$SAVI[1], y = wet_row$STR[1], xend = dry_row$SAVI[1], yend = dry_row$STR[1]),
        color = "black", linewidth = 1.1, linetype = "dashed"
      ) +
      geom_point(data = extent_pts, aes(x = SAVI, y = STR, color = Condition), size = 4.5) +
      scale_color_manual(values = c("firebrick", "dodgerblue4")) +
      coord_cartesian(xlim = c(0, 0.3), ylim = c(0, 2)) +
      labs(
        title    = paste("OPTRAM Extent Vector -", yr),
        subtitle = paste0("Length: ", round(length_vec, 3), " | Angle: ", round(angle_deg, 1), "°"),
        x        = "SAVI",
        y        = "STR",
        color    = "Extreme Months"
      ) +
      theme_classic() +
      theme(
        plot.title      = element_text(face = "bold", size = 13, hjust = 0.5),
        plot.subtitle   = element_text(size = 11, hjust = 0.5),
        axis.title      = element_text(face = "bold", size = 11),
        panel.border    = element_rect(color = "black", fill = NA, linewidth = 0.8),
        legend.position = "right"
      )
    
    ggsave(file.path(base_output_dir, as.character(yr), paste0("extent_plot_", yr, ".png")),
           plot = p_ext, width = 7.5, height = 5.5, dpi = 300)
    
    message(paste("✓ Processed Trajectory and Extent for year:", yr))
  }
}

extent_df <- bind_rows(extent_records)
write.csv(extent_df, file.path(base_output_dir, "extent_metrics_2017_2025.csv"), row.names = FALSE)

#---- Correlations: Annual & Monthly (PRISM Precipitation) ----
prism_file_path <- "C:/Users/nitsa/Desktop/Uni/RS_for_arid/Arid_project/Data/Precipitation Values/Byy Months/PRISM_ppt_Unlikely_to_change_800m_201701_202512_40.1756_-112.4891.csv"

prism_raw <- read.csv(prism_file_path, skip = 10, stringsAsFactors = FALSE)
colnames(prism_raw) <- c("Date", "Rainfall_mm")

prism_clean <- prism_raw %>%
  mutate(
    Year      = as.numeric(substr(Date, 1, 4)),
    Month_Num = as.numeric(substr(Date, 6, 7))
  ) %>%
  filter(!is.na(Rainfall_mm) & Year >= 2017 & Year <= 2025)

# חישוב גשם שנתי
annual_rain <- prism_clean %>%
  group_by(Year) %>%
  summarise(Annual_Rainfall_mm = sum(Rainfall_mm, na.rm = TRUE), .groups = "drop")

merged_annual <- merge(extent_df, annual_rain, by = "Year")
write.csv(merged_annual, file.path(base_output_dir, "optram_extent_and_rainfall_results.csv"), row.names = FALSE)

# א. גרף קורלציה שנתית: אורך Extent מול גשם שנתי
p_corr_length <- ggplot(merged_annual, aes(x = Annual_Rainfall_mm, y = Length)) +
  geom_point(size = 4, color = "dodgerblue4") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", fill = "pink", alpha = 0.3) +
  geom_text(aes(label = Year), vjust = -1, size = 3.8, fontface = "bold") +
  labs(
    title    = "Correlation: Extent Vector Length vs. Annual Rainfall",
    subtitle = "Rush Valley, Utah (2017-2025)",
    x        = "Annual Rainfall (mm)",
    y        = "Extent Vector Length"
  ) +
  theme_classic() +
  theme(plot.title = element_text(face = "bold", size = 13, hjust = 0.5), plot.subtitle = element_text(size = 11, hjust = 0.5))

# ב. גרף קורלציה שנתית: זווית Extent מול גשם שנתי
p_corr_angle <- ggplot(merged_annual, aes(x = Annual_Rainfall_mm, y = Angle_deg)) +
  geom_point(size = 4, color = "darkgreen") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", fill = "pink", alpha = 0.3) +
  geom_text(aes(label = Year), vjust = -1, size = 3.8, fontface = "bold") +
  labs(
    title    = "Correlation: Extent Vector Angle vs. Annual Rainfall",
    subtitle = "Rush Valley, Utah (2017-2025)",
    x        = "Annual Rainfall (mm)",
    y        = "Extent Vector Angle (°)"
  ) +
  theme_classic() +
  theme(plot.title = element_text(face = "bold", size = 13, hjust = 0.5), plot.subtitle = element_text(size = 11, hjust = 0.5))

# ג. גרף קורלציה חודשית רציפה: לחות (STR) מול משקעים חודשיים
all_monthly_df <- bind_rows(all_monthly_means)
merged_monthly <- merge(all_monthly_df, prism_clean, by = c("Year", "Month_Num"))

p_corr_monthly <- ggplot(merged_monthly, aes(x = Rainfall_mm, y = STR)) +
  geom_point(aes(color = Month), size = 3, alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linetype = "dashed") +
  scale_color_viridis_d(option = "turbo") +
  labs(
    title    = "Monthly Correlation: Soil Moisture (STR) vs. Monthly Precipitation",
    subtitle = "All Observations across 2017-2025",
    x        = "Monthly Rainfall (mm)",
    y        = "Mean STR (Transformed Reflectance)",
    color    = "Month"
  ) +
  theme_classic() +
  theme(plot.title = element_text(face = "bold", size = 13, hjust = 0.5), plot.subtitle = element_text(size = 11, hjust = 0.5))

# שמירת גרפי הקורלציה
ggsave(file.path(base_output_dir, "correlation_length_vs_rainfall.png"), plot = p_corr_length, width = 7, height = 5, dpi = 300)
ggsave(file.path(base_output_dir, "correlation_angle_vs_rainfall.png"), plot = p_corr_angle, width = 7, height = 5, dpi = 300)
ggsave(file.path(base_output_dir, "correlation_monthly_str_vs_rainfall.png"), plot = p_corr_monthly, width = 7.5, height = 5, dpi = 300)

message("All tasks completed successfully. Scripts are ready for Git commit.")