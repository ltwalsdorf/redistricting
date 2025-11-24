#!/usr/bin/env python3
"""Convert a GeoJSON containing multiple districts into one ESRI Shapefile per district.

Usage example:
  python redistrictrAnalysis/shapeFileConversion.py redistrictrAnalysis/data/example2.geojson


The script will try to auto-detect a district column (names containing 'dist', 'district', or 'cd').
You can override with --column.
"""
from __future__ import annotations

import argparse
import os
import re
import unicodedata
from collections import Counter
from typing import Optional

import geopandas as gpd


def slugify(value: str) -> str:
    """Sanitize a string to be safe for filenames."""
    value = str(value)
    value = unicodedata.normalize('NFKD', value)
    value = value.encode('ascii', 'ignore').decode('ascii')
    value = re.sub(r"[^A-Za-z0-9._-]", "_", value)
    value = re.sub(r"_+", "_", value)
    return value.strip('_')[:100]


def shorten_fieldnames(gdf: gpd.GeoDataFrame, max_len: int = 10) -> gpd.GeoDataFrame:
    """Ensure non-geometry column names are <= max_len (DBF limitation for shapefiles).

    This makes a best-effort unique mapping by truncation and numeric suffixes.
    """
    cols = list(gdf.columns)
    if 'geometry' in cols:
        cols.remove('geometry')

    mapping = {}
    seen = Counter()
    for col in cols:
        base = col[:max_len]
        if base in seen:
            # append numeric suffix (keeps <= max_len by trimming)
            suffix = str(seen[base] + 1)
            allowed = max_len - len(suffix)
            new = (base[:allowed] + suffix) if allowed > 0 else (base[:max_len])
        else:
            new = base
        seen[base] += 1
        # ensure unique overall
        i = 1
        candidate = new
        while candidate in mapping.values():
            tail = str(i)
            allowed = max_len - len(tail)
            candidate = (new[:allowed] + tail) if allowed > 0 else new[:max_len]
            i += 1
        mapping[col] = candidate

    return gdf.rename(columns=mapping)


def detect_district_column(gdf: gpd.GeoDataFrame) -> Optional[str]:
    names = list(gdf.columns)
    candidates = [c for c in names if c.lower().find('dist') != -1 or c.lower().find('district') != -1 or c.lower().find('cd') != -1]
    if candidates:
        return candidates[0]

    # fallback: look for a column with reasonably few unique values
    best = None
    best_count = gdf.shape[0] + 1
    for c in names:
        if c == 'geometry':
            continue
        try:
            nuniq = gdf[c].nunique(dropna=True)
        except Exception:
            continue
        if 1 < nuniq < best_count:
            best = c
            best_count = nuniq

    return best


def write_shapefiles_per_district(in_path: str,
                                  column: Optional[str] = None,
                                  guess: bool = True,
                                  outdir: Optional[str] = None) -> None:
    gdf = gpd.read_file(in_path)

    # derive outdir only if not provided
    if outdir is None:
        # remove trailing .geojson (even if uppercase)
        in_path_without_suffix = re.sub(r'\.geojson$', '', in_path, flags=re.IGNORECASE)
        outdir = in_path_without_suffix + "_shapefiles"

    # actually create it
    os.makedirs(outdir, exist_ok=True)
    print(f"Writing to directory: {os.path.abspath(outdir)}")

    if column is None and guess:
        column = detect_district_column(gdf)
    if column is None:
        raise ValueError(f"Could not detect a district column automatically. Columns available: {list(gdf.columns)}")
    if column not in gdf.columns:
        raise ValueError(f"Specified column '{column}' not found in GeoJSON. Available: {list(gdf.columns)}")

    values = gdf[column].dropna().unique()
    print(f"Found {len(values)} districts in column '{column}'.")

    for val in values:
        subset = gdf[gdf[column] == val].copy()
        if subset.empty:
            continue
        safe_val = slugify(val)
        base_name = f"{slugify(column)}_{safe_val}" if safe_val else f"{slugify(column)}_{str(val)}"

        out_gdf = subset
        out_path = os.path.join(outdir, f"{base_name}.geojson")
        print(f"Writing {len(out_gdf)} features for '{val}' -> {out_path}")
        out_gdf.to_file(out_path, driver='GeoJSON')

def main():
    p = argparse.ArgumentParser(description="Split a GeoJSON into one shapefile per district/value")
    p.add_argument('input', help='Path to input GeoJSON file')
    p.add_argument('--outdir', '-o', default='shapefiles', help='Output directory')
    p.add_argument('--column', '-c', default=None, help='Column name that identifies the district (optional)')
    p.add_argument('--no-guess', dest='guess', action='store_false', help='Disable automatic detection of district column')

    args = p.parse_args()

    try:
        write_shapefiles_per_district(args.input, column=args.column, guess=args.guess)
    except Exception as e:
        print(f"Error: {e}")
        raise


if __name__ == '__main__':
    main()
