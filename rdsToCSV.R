# ---------------------------------------------------------
# Convert an RDS file containing spatial data to GeoJSON
# ---------------------------------------------------------

library(sf)

# ---- CONFIGURE INPUT / OUTPUT ----
input_file <- "IL_cd_2020_map.rds"
output_geojson <- "IL_cd_2020_map.geojson"

# ---- LOAD THE RDS ----
obj <- readRDS(input_file)

# ---- CHECK & EXPORT ----
if (inherits(obj, "sf")) {
  
  message("Detected: sf spatial object")
  message("Exporting to GeoJSON...")

  st_write(obj, output_geojson, driver = "GeoJSON", delete_dsn = TRUE)

  message(paste("✅ Export complete:", output_geojson))

} else {
  stop("❌ The RDS file does not contain an sf object. Cannot export to GeoJSON.")
}

# ---------------------------------------------------------
# End of script
# ---------------------------------------------------------
