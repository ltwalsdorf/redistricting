library(sf)
library(dplyr)
library(redistmetrics)
library(redist)

fileName <- "example4"
input <- paste0("data/", fileName, ".geojson")
output <- paste0("data/", fileName, "_compactness.csv")

shp <- st_read(input, quiet = TRUE) |>
  st_transform(5070)

perims <- prep_perims(shp)

metrics <- tibble(
  district = shp$districtr
) |>
  distinct() |>
  arrange(district)

metrics <- metrics |>
  mutate(
    comp_bc        = comp_bc(plans = shp$districtr, shp = shp),
    comp_box_reock = comp_box_reock(plans = shp$districtr, shp = shp),
    comp_ch        = comp_ch(plans = shp$districtr, shp = shp),
    # comp_fh        = comp_fh(plans = shp$districtr, shp = shp),
    # comp_frac_kept = comp_frac_kept(plans = shp$districtr, shp = shp),
    # comp_log_st    = comp_log_st(plans = shp$districtr, shp = shp),
    comp_lw        = comp_lw(plans = shp$districtr, shp = shp),
    comp_polsby    = comp_polsby(plans = shp$districtr, shp = shp),
    comp_reock     = comp_reock(plans = shp$districtr, shp = shp),
    comp_schwartz  = comp_schwartz(plans = shp$districtr, shp = shp),
    comp_skew      = comp_skew(plans = shp$districtr, shp = shp)
    # comp_x_sym     = comp_x_sym(plans = shp$districtr, shp = shp),
    # comp_y_sym     = comp_y_sym(plans = shp$districtr, shp = shp)
  )

# Optional reference area/perimeter by district
shp$.__area_m2 <- as.numeric(st_area(shp))
shp$.__perim_m <- as.numeric(st_length(st_cast(st_boundary(shp), "MULTILINESTRING")))

ref <- shp |>
  st_drop_geometry() |>
  group_by(district = districtr) |>
  summarize(area_m2 = sum(.__area_m2, na.rm = TRUE),
            perim_m = sum(.__perim_m, na.rm = TRUE), .groups = "drop")

district_geoms <- shp |>
  group_by(district = districtr) |>
  summarize(geometry = st_union(geometry), .groups = "drop")

# Convert geometry to WKT
district_geoms <- district_geoms |>
  mutate(
    geometry_wkt = st_as_text(geometry)
  ) |>
  st_drop_geometry()

# --------------------------------------------

# Combine everything
out <- metrics |>
  left_join(ref, by = "district") |>
  left_join(district_geoms, by = "district") |>
  mutate(district = as.character(district))

# Write final CSV
readr::write_csv(out, output)
