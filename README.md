# 2020 Illinois Congressional Districts

## Redistricting Requirements

In Illinois, districts must, under *Ill. Const. Art. IV, § 3*:

1. Be contiguous
2. Have equal populations
3. Be geographically compact

### Algorithmic Constraints

We enforce a maximum population deviation of **0.5%**.

---

## Data Sources

Data for Illinois comes from the ALARM Project’s [2020 Redistricting Data Files](https://alarm-redist.github.io/posts/2021-08-10-census-2020/).

---

## Pre-processing Notes

No manual pre-processing decisions were necessary.

---

## Simulation Notes

We sample **60,000 districting plans** for Illinois across two independent runs of the SMC algorithm, and then thin the sample down to **5,000 plans**.

To balance county and municipality splits, we create *pseudocounties* for use in the county constraint, which leads to fewer municipality splits than using a county constraint. These are counties outside of Cook County and DuPage County. Within Cook County and DuPage County, each municipality is its own pseudocounty as well. Cook County and DuPage County were chosen since they are necessarily split by congressional districts.

To comply with the federal VRA and to respect communities of interest, we add **hinge Gibbs constraints of strength 20** targeting one majority-Black district (IL-01) and one majority-Hispanic district (IL-04), focusing on districts with relatively higher proportions of Black and Hispanic voters. We also apply a **hinge Gibbs constraint of strength 10** to discourage packing of Black voters.

---

## Contents

- `IL_cd_2020_stats.csv` — contains summary statistics on the sampled redistricting plans
- `IL_cd_2020_plans.rds` — a compressed `redist_plans` object containing the matrix of precinct/block assignments for further analysis
- `IL_cd_2020_map.rds` — a compressed `redist_map` object containing the precinct/block shapefile and demographic data

Both the `redist_plans` and `redist_map` objects are intended to be used with the [redist package](https://alarm-redist.github.io/redist/).

---

### Codebook for Summary Statistics

- `draw`: unique identifier for each sample. Non-numeric draw names are real-world plans, e.g., `cd_2010` for an enacted 2010 plan.
- `district`: district identifier. District numbers roughly match those in the enacted plan, but correspondence may not be perfect.
- `chain`: number identifying the run of the redistricting algorithm used to produce this draw (for diagnostics).
- `pop_overlap`: fraction of people in this plan who reside in the same-numbered district in the enacted plan.
- `total_pop`: total population of each district.
- `total_vap`: total voting-aged population of each district.
- `pop_*`, `vap_*`: total (voting-aged) population within racial and ethnic groups for each district. Variable codes documented [here](https://github.com/alarm-redist/census-2020#data-format).
- `plan_dev`: maximum population deviation among districts in the plan, computed as `max(abs(distr_pop - target_pop)/target_pop)`.
- `comp_edge`: compactness (fraction of internal edges kept). Higher values indicate more compactness.
- `comp_polsby`: compactness via Polsby-Popper score. Higher values indicate more compactness.
- `county_splits`: number of counties belonging to more than one district.
- `muni_splits`: number of Census Designated Places belonging to more than one district.
- `*_##_dem_*`, `*_##_rep_*`: vote counts for statewide Democratic and Republican candidates in a given election ([docs](https://github.com/alarm-redist/census-2020#data-format)).
- `adv_##`, `arv_##`: average vote counts for statewide Democratic and Republican candidates in a certain year ([docs](https://github.com/alarm-redist/census-2020#data-format)).
- `ndv`, `nrv`: averages of `adv_##` and `arv_##` across all available elections.
- `ndshare`: normal Democratic share, computed as `ndv / (ndv + nrv)`.
- `e_dvs`: average Democratic vote share, computed as the average of the Democratic vote share across statewide elections.
- `pr_dem`: probability seat is represented by a Democrat (fraction of elections with majority Democratic share).
- `e_dem`: expected number of Democratic seats in the plan (sum of `pr_dem` values).
- `pbias`: partisan bias at 50% vote share, averaged across elections. Positive = Republican bias.
- `egap`: efficiency gap, averaged across elections. Positive = Republican bias.

---
