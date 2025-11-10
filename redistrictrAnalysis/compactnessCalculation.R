library(sf)
library(dplyr)
library(redistmetrics)

shp <- st_read("/data/illinoisExample.geojson", quiet = TRUE) |>
  st_transform(5070)  # project to equal-area

perims <- prep_perims(shp)

metrics <- tibble(
  district = shp$districtr
) |>
  distinct() |>
  arrange(district)

add <- function(x) setNames(list(x), deparse(substitute(x)))

metrics <- metrics |>
  mutate(
    comp_bc        = comp_bc(plans = shp$districtr, shp = shp),
    comp_box_reock = comp_box_reock(plans = shp$districtr, shp = shp),
    comp_ch        = comp_ch(plans = shp$districtr, shp = shp),
    comp_edges_rem = comp_edges_rem(plans = shp$districtr, shp = shp),
    comp_fh        = comp_fh(plans = shp$districtr, shp = shp),
    comp_frac_kept = comp_frac_kept(plans = shp$districtr, shp = shp),
    comp_log_st    = comp_log_st(plans = shp$districtr, shp = shp),
    comp_lw        = comp_lw(plans = shp$districtr, shp = shp),
    comp_polsby    = comp_polsby(plans = shp$districtr, shp = shp, perims = perims),
    comp_reock     = comp_reock(plans = shp$districtr, shp = shp),
    comp_schwartz  = comp_schwartz(plans = shp$districtr, shp = shp),
    comp_skew      = comp_skew(plans = shp$districtr, shp = shp),
    comp_x_sym     = comp_x_sym(plans = shp$districtr, shp = shp),
    comp_y_sym     = comp_y_sym(plans = shp$districtr, shp = shp)
  )

# Optional reference area/perimeter by district
shp$.__area_m2 <- as.numeric(st_area(shp))
shp$.__perim_m <- as.numeric(st_length(st_cast(st_boundary(shp), "MULTILINESTRING")))

ref <- shp |>
  st_drop_geometry() |>
  group_by(district = districtr) |>
  summarize(area_m2 = sum(.__area_m2, na.rm = TRUE),
            perim_m = sum(.__perim_m, na.rm = TRUE), .groups = "drop")

out <- left_join(metrics, ref, by = "district")
# readr::write_csv(out, "/mnt/data/il_compactness.csv")