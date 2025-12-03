############################################################
# DIAGNOSTIC: Inspect IL_cd_2020_map in detail
# Output written to: output.txt
############################################################

output_file <- "output.txt"

# Start sinking all printed output
sink(output_file, split = FALSE)

library(sf)

cat("\n====================\n")
cat("GENERAL INFORMATION\n")
cat("====================\n\n")

il <- readRDS("IL_cd_2020_map.rds")

# Class
cat("Class:\n")
print(class(il))

# Simple high-level structure
cat("\nStructure (first 2 levels):\n")
str(il, max.level = 2)

cat("\n\n====================\n")
cat("COLUMN NAMES\n")
cat("====================\n\n")
print(names(il))

cat("\n\n====================\n")
cat("COLUMN TYPES\n")
cat("====================\n\n")
print(sapply(il, class))

cat("\n\n====================\n")
cat("DISTRICT LABEL ANALYSIS\n")
cat("====================\n\n")

if ("cd_2020" %in% names(il)) {
    dist <- il$cd_2020

    cat("Summary of district labels:\n")
    print(summary(dist))

    cat("\nUnique district labels:\n")
    print(unique(dist))

    # check for glue-problematic characters inside district labels
    bad_chars <- grepl("[\\{\\}]", as.character(dist))
    if (any(bad_chars)) {
        cat("\n❗ District labels containing { or }:\n")
        print(unique(dist[bad_chars]))
    } else {
        cat("\n✔ No { or } found in district labels.\n")
    }

    # NA district labels
    if (any(is.na(dist))) {
        cat("\n❗ NA district labels detected.\n")
        print(which(is.na(dist)))
    } else {
        cat("\n✔ No NA district labels.\n")
    }

    # factor detection
    if (is.factor(dist)) {
        cat("\n❗ District labels are a FACTOR (can break glue):\n")
        print(levels(dist))
    } else {
        cat("\n✔ District labels are NOT a factor.\n")
    }
}

cat("\n\n====================\n")
cat("REDIST-SPECIFIC ATTRIBUTES\n")
cat("====================\n\n")

attrs <- attributes(il)
print(attrs[names(attrs) != "class"])

cat("\n\n====================\n")
cat("ADJACENCY LIST CHECK\n")
cat("====================\n\n")

if ("adj" %in% names(il)) {
    adj <- il$adj

    cat("Adjacency list type:\n")
    print(class(adj))

    if (is.list(adj)) {
        cat("\nLength of adjacency list: ", length(adj), "\n")
        cat("Sample adjacency entry:\n")
        print(adj[[1]])
    }

    # Check adjacency for glue-breaking characters
    adj_char <- unlist(lapply(adj, as.character))
    bad_adj <- grepl("[\\{\\}]", adj_char)

    if (any(bad_adj)) {
        cat("\n❗ Adjacency list contains glue-breaking characters { or }.\n")
        print(unique(adj_char[bad_adj]))
    } else {
        cat("\n✔ No glue-breaking characters in adjacency list.\n")
    }
}

cat("\n\n====================\n")
cat("GEOMETRY / CRS INFO\n")
cat("====================\n\n")

cat("sf geometry column:\n")
print(attr(il, "sf_column"))

cat("\nCRS:\n")
print(st_crs(il))

cat("\nBounding box:\n")
print(st_bbox(il))

# Geometry validity
cat("\nGeometry validity (first 10 rows):\n")
print(st_is_valid(il[1:10,]))

cat("\n\n====================\n")
cat("END OF DIAGNOSTIC REPORT\n")
cat("====================\n\n")

# Stop sinking
sink()
