############################################################
# Compactness + area/perimeter for plan #1 (cd_2020)
# Output: idealPlan.csv (no list-columns)
############################################################

library(sf)
library(redist)
library(redistmetrics)
library(dplyr)
library(rlang)

options(error = function() {
  traceback(10)
  rlang::last_trace()
})

#-----------------------------
# 1. Load map and define plan
#-----------------------------
il_map <- readRDS("IL_cd_2020_map.rds")

# Compactness functions expect valid AGR metadata
il_map <- st_set_agr(il_map, "constant")

plan1 <- il_map$cd_2020
dist_ids <- sort(unique(plan1))

# Projection for area/perimeter (same as Script 1)
epsg_code <- 2790

#-----------------------------
# 2. Compactness metrics
#-----------------------------
# Use explicit namespace because redist masks redistmetrics
comp_bc_vals         <- redistmetrics::comp_bc        (plans = plan1, shp = il_map)
comp_box_reock_vals  <- redistmetrics::comp_box_reock (plans = plan1, shp = il_map)
comp_ch_vals         <- redistmetrics::comp_ch        (plans = plan1, shp = il_map)
comp_lw_vals         <- redistmetrics::comp_lw        (plans = plan1, shp = il_map)
comp_schwartz_vals   <- redistmetrics::comp_schwartz  (plans = plan1, shp = il_map)
comp_skew_vals       <- redistmetrics::comp_skew      (plans = plan1, shp = il_map)

# Metrics that require projected input
comp_polsby_vals     <- redistmetrics::comp_polsby    (plans = plan1, shp = il_map, epsg = epsg_code)
comp_reock_vals      <- redistmetrics::comp_reock     (plans = plan1, shp = il_map, epsg = epsg_code)

#-----------------------------
# 3. Area + Perimeter (IDENTICAL to original Script 1)
#-----------------------------
il_map_m <- st_transform(il_map, epsg_code)

# Union precincts → district-wide geometry
dist_geom <- il_map_m |>
  mutate(district = plan1) |>
  group_by(district) |>
  summarise(geometry = st_union(geometry), .groups = "drop") |>
  arrange(match(district, dist_ids))

# Compute area/perimeter from unioned geometry
dist_geom <- dist_geom |>
  mutate(
    area_m2 = as.numeric(st_area(geometry)),
    perim_m = as.numeric(
      st_length(st_cast(st_boundary(geometry), "MULTILINESTRING"))
    )
  )

#-----------------------------
# 4. Combine compactness + area/perimeter
#-----------------------------
results_plan1 <- dist_geom |>
  mutate(
    comp_bc        = comp_bc_vals,
    comp_box_reock = comp_box_reock_vals,
    comp_ch        = comp_ch_vals,
    comp_lw        = comp_lw_vals,
    comp_polsby    = comp_polsby_vals,
    comp_reock     = comp_reock_vals,
    comp_schwartz  = comp_schwartz_vals,
    comp_skew      = comp_skew_vals
  ) |>
  st_drop_geometry() |>
  as_tibble()

#-----------------------------
# 5. Order columns
#-----------------------------
results_plan1 <- results_plan1 |>
  select(
    district,
    comp_bc,
    comp_box_reock,
    comp_ch,
    comp_lw,
    comp_polsby,
    comp_reock,
    comp_schwartz,
    comp_skew,
    area_m2,
    perim_m
  )

#-----------------------------
# 6. Write CSV
#-----------------------------
write.csv(results_plan1, "idealPlanExample.csv", row.names = FALSE, quote = FALSE)

cat("✅ idealPlanExample.csv has been created.\n")
