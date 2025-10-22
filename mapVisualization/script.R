library(sf)
library(ggplot2)

# Load your RDS file
map_data <- readRDS("IL_cd_2020_map.rds")

# Sanity check (optional: saves structure info to text file instead of printing)
sink("mapVisualization/output_info.txt")
print(map_data)
sink()

# Create ggplot map
p <- ggplot(map_data) +
  geom_sf(fill = "grey90", color = "black", linewidth = 0.3) +
  ggtitle("Illinois Congressional Districts (2020)") +
  theme_minimal()

# Save to PNG file
ggsave("mapVisualization/output.png", plot = p, width = 8, height = 6, dpi = 300)
