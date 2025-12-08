############################################################
# Compactness + area/perimeter for many plans
# Each plan ID in plan_ids → its own CSV in idealPlans/
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
# 0. Plan IDs to process
#-----------------------------
plan_ids <- c(
  566, 1680, 1940, 750, 446, 31925, 326, 2059, 812, 1268, 2345, 32426, 31313,
  31018, 31179, 31651, 32159, 32219, 442, 30605, 30822, 31373, 32104, 32317,
  32494, 31952, 31142, 32333, 31454, 369, 30443, 31385, 31991, 32371, 1187,
  31676, 1534, 1153, 30491, 30175, 547, 31737, 277, 1692, 2470, 42, 653, 711,
  185, 30502, 31364, 1422, 37, 1224, 30068, 30151, 1098, 1797, 1403, 2381,
  30344, 30811, 30823, 32129, 31347, 30371, 30429, 31352, 31448, 31705, 31834,
  30098, 31032, 31334, 32475, 30942, 1386, 31546, 32213, 31318, 1299, 1460,
  30276, 31162, 282, 403, 960, 1229, 31218, 1351, 682, 1850, 414, 30967, 1788,
  2247, 2358, 30923, 32077
)

#-----------------------------
# 1. Load map and plans
#-----------------------------
il_map <- readRDS("IL_cd_2020_map.rds")
il_map <- st_set_agr(il_map, "constant")

plans_obj <- readRDS("IL_cd_2020_plans.rds")

# matrix of precinct × plans (10084 × 5001)
plan_mat <- attr(plans_obj, "plans")

# factor of draw labels: "cd_2020", "1", "2", ..., "5000"
draw_levels <- levels(plans_obj$draw)

# Projection for area/perimeter
epsg_code <- 2790

# Transform map once for geometric operations
il_map_m <- st_transform(il_map, epsg_code)

# Create output folder if it doesn't exist
if (!dir.exists("idealPlans")) dir.create("idealPlans")

#-----------------------------
# 2. Loop over requested plans
#-----------------------------
for (pid in plan_ids) {

  draw_label <- as.character(pid)

  if (!draw_label %in% draw_levels) {
    warning("Plan/draw ", pid,
            " not found in IL_cd_2020_plans.rds (max draw is ",
            max(as.numeric(draw_levels[-1])), "); skipping.")
    next
  }

  message("\n==============================")
  message("Processing plan (draw): ", pid)
  message("==============================\n")

  # Column index in the plans matrix corresponding to this draw
  col_idx <- which(draw_levels == draw_label)

  # Precinct-level district assignment vector for this plan
  plan_vec <- plan_mat[, col_idx]

  dist_ids <- sort(unique(plan_vec))

  #-----------------------------
  # Compactness metrics
  #-----------------------------
  comp_bc_vals         <- redistmetrics::comp_bc        (plans = plan_vec, shp = il_map)
  comp_box_reock_vals  <- redistmetrics::comp_box_reock (plans = plan_vec, shp = il_map)
  comp_ch_vals         <- redistmetrics::comp_ch        (plans = plan_vec, shp = il_map)
  comp_lw_vals         <- redistmetrics::comp_lw        (plans = plan_vec, shp = il_map)
  comp_schwartz_vals   <- redistmetrics::comp_schwartz  (plans = plan_vec, shp = il_map)
  comp_skew_vals       <- redistmetrics::comp_skew      (plans = plan_vec, shp = il_map)

  # Metrics requiring projected input
  comp_polsby_vals     <- redistmetrics::comp_polsby    (plans = plan_vec, shp = il_map, epsg = epsg_code)
  comp_reock_vals      <- redistmetrics::comp_reock     (plans = plan_vec, shp = il_map, epsg = epsg_code)

  #-----------------------------
  # Area + Perimeter
  #-----------------------------
  dist_geom <- il_map_m |>
    mutate(district = plan_vec) |>
    group_by(district) |>
    summarise(geometry = st_union(geometry), .groups = "drop") |>
    arrange(match(district, dist_ids)) |>
    mutate(
      area_m2 = as.numeric(st_area(geometry)),
      perim_m = as.numeric(
        st_length(st_cast(st_boundary(geometry), "MULTILINESTRING"))
      )
    )

  #-----------------------------
  # Combine compactness + area/perimeter
  #-----------------------------
  results <- dist_geom |>
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
    as_tibble() |>              # <-- critical fix
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
  # Write CSV for this plan
  #-----------------------------
  out_file <- file.path("idealPlans", paste0("idealPlan_", pid, ".csv"))
  write.csv(results, out_file, row.names = FALSE, quote = FALSE)

  message("✔ Output written to: ", out_file, "\n")
}

message("\nDone processing all requested plan IDs (valid draws only).\n")
