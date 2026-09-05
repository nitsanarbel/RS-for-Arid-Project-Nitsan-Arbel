# Soil Moisture Dynamics Using the OPTRAM Model in Rush Valley, Utah

**Course:** Remote Sensing in Arid Regions  
**Author:** Nitsan Arbel  

---

## Project Overview
This study estimates long-term soil moisture dynamics across **Rush Valley, Utah** (2017–2025) using the **OPTRAM (Optical Trapezoid Model)** applied to Sentinel-2 satellite imagery. The model relates the Soil-Adjusted Vegetation Index (**SAVI**) to Shortwave Infrared Transformed Reflectance (**STR**) to capture surface moisture transitions across semi-arid shrubland ecosystems. In addition, model outputs and seasonal extent metrics are validated against gridded precipitation data from the **PRISM Climate Group**.

---

## Methodology & Workflow
1. **Satellite Pre-processing:** Acquire and filter cloud-free Sentinel-2 L2A scenes (tile `12TUK`) over the defined Area of Interest (AOI).
2. **OPTRAM Calibration:** Construct linear dry and wet trapezoid boundaries ($STR_{dry}$ and $STR_{wet}$) in the SAVI–STR feature space.
3. **Seasonal Trajectories:** Trace monthly mean trajectories with SAVI constrained between 0.0 and 0.3.
4. **Extent Vector Analysis:** Measure annual vector distance ($Length$) and direction ($Angle$) connecting the most extreme dry and wet months.
5. **Climate Correlation:** Examine annual and continuous monthly Pearson correlations between PRISM precipitation data and soil moisture metrics ($STR$ and Extent parameters).

---

## Repository Structure
* `run.R` - Complete operational pipeline (data processing, trapezoid modeling, trajectory extraction, and correlation analysis).
* `functions.R` - Helper functions for Copernicus Data Space Ecosystem (CDSE) API authentication, image fetching, and model evaluation.
* `new_aoi.gpkg` - Spatial boundary of the study area in Rush Valley, Utah.
* `.gitignore` - Rules omitting heavy rasters, processed outputs, and private API credentials.