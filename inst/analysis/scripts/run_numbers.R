require(data.table)
require(paramix)

.args <- if (interactive()) {
  c(
    file.path("figure", "fig_utilities.rda"),
    file.path("input", "population.rds"),
    file.path("input", "disease_pars.rda"),
    file.path("output", "incidence.rds"),
    file.path("output", "consolidated.rds")
  )
} else {
  commandArgs(trailingOnly = TRUE)
}

load(.args[1])

inc_dt <- readRDS(.args[4])
model_partition <- c(inc_dt[method == "f_mean", unique(model_partition)], 101)
inc_dt <- inc_dt[method == "f_mean"][,
  .(value = sum(value), capita = sum(unique(capita))),
  by = .(iso3 = place, pathogen, intervention, time)
]
isoset <- inc_dt[, unique(iso3)]

load(.args[3])
pop_dt <- readRDS(.args[2])[iso3 %in% isoset]

bound_pop_dt <- pop_dt[,
  .(
    from = c(from, max(from) + 1L),
    weight = c(weight, 0)
  ),
  by = iso3
]

ifr_dt <- bound_pop_dt[,
  ifr_opts |>
    lapply(\(fp) {
      parameter_summary(fp, .SD, model_partition, resolution = 102)
    }) |>
    rbindlist(idcol = "pathogen"),
  by = iso3
][model_category == 4][x == max(x)] |>
  dcast(iso3 + pathogen ~ method, value.var = "value")

ifr_dt[, place := fifelse(iso3 == "AFG", "LMIC", "HIC")]

for (path in ifr_dt[, unique(pathogen)]) {
  cat(path, " 65+ IFR", "\n")
  for (plc in ifr_dt[, unique(place)]) {
    cat(plc, ": [1] MEAN METHOD [2] PARAMIX", "\n")
    cat(
      paste0(
        ifr_dt[
          pathogen == path & place == plc,
          signif(100 * c(f_mean, wm_f), 3)
        ],
        "%"
      ),
      "\n"
    )
    cat("% INCREASE WITH PARAMIX", "\n")
    cat(
      ifr_dt[
        pathogen == path & place == plc,
        signif(100 * (wm_f - f_mean) / f_mean, 3)
      ],
      "%",
      "\n"
    )
  }
  cat("\n")
}

ts_dt <- readRDS(.args[4])

joinvars <- c("method", "place", "pathogen")
base_dt <- ts_dt[
  intervention == "none",
  .SD,
  .SDcols = -c("intervention", "capita")
][, .(deaths = sum(deaths)), by = c(joinvars)]
int_dt <- ts_dt[
  intervention != "none",
  .(
    deaths = sum(deaths),
    capita = sum(unique(capita))
  ),
  by = c(joinvars, "intervention")
][
  base_dt,
  on = c(joinvars)
]
int_dt[, averted_death := i.deaths - deaths]
int_dt[, place := fifelse(place == "AFG", "LMIC", "HIC")]

melt_int_dt <- int_dt[method %in% c("f_mid", "wm_f")] |>
  dcast(place + pathogen + intervention ~ method, value.var = "averted_death")
melt_int_dt[, pct_overestimate := signif(100 * (f_mid - wm_f) / wm_f, 3)]

cat("% OVERESTIMATE BENEFIT (DEATHS AVERTED) COMPARED TO PARAMIX", "\n")
for (plc in melt_int_dt[, unique(place)]) {
  for (path in melt_int_dt[, unique(pathogen)]) {
    cat(path, " ", plc, ": [1] VAX OLDER [2] VAX WORKING [3] VAX YOUNG", "\n")
    cat(
      paste0(
        melt_int_dt[
          pathogen == path & place == plc,
          setNames(pct_overestimate, intervention)
        ],
        "%"
      ),
      "\n"
    )
  }
  cat("\n")
}

ylls_dt <- readRDS(.args[5])
base_dt <- ylls_dt[
  intervention == "none",
  .SD,
  .SDcols = -c("intervention")
]
int_dt <- ylls_dt[intervention != "none"][
  base_dt,
  on = setdiff(names(base_dt), "YLL")
]
int_dt[, averted_yll := i.YLL - YLL]
int_dt[,
  sim_method := factor(
    sim_method,
    levels = names(model_assumption_labels),
    ordered = TRUE
  )
]
int_dt[,
  method := factor(
    method,
    levels = names(model_assumption_labels),
    ordered = TRUE
  )
]
int_dt <- int_dt[sim_method == "wm_f"][, sim_method := NULL]
int_dt[, place := fifelse(place == "AFG", "LMIC", "HIC")]

melt_yll_dt <- int_dt[method %in% c("mean_f", "wm_f")] |>
  dcast(pathogen + place + intervention ~ method, value.var = "averted_yll")
melt_yll_dt[, pct_overestimate := signif(100 * (mean_f - wm_f) / wm_f, 3)]

cat("% OVERESTIMATE YLLS COMPARED TO PARAMIX", "\n")
for (plc in melt_yll_dt[, unique(place)]) {
  for (path in melt_yll_dt[, unique(pathogen)]) {
    cat(path, " ", plc, ": [1] VAX OLDER [2] VAX WORKING [3] VAX YOUNG", "\n")
    cat(
      paste0(
        melt_yll_dt[
          pathogen == path & place == plc,
          setNames(pct_overestimate, intervention)
        ],
        "%"
      ),
      "\n"
    )
  }
  cat("\n")
}

# Published benchmarks from Goodfellow et al. (2025)
published_ifr <- data.table(
  place = c("LMIC", "LMIC", "HIC", "HIC"),
  pathogen = c("FLU", "SC2", "FLU", "SC2"),
  pct_increase = c(35.9, 40.7, 58.3, 73.2)
)

published_deaths <- data.table(
  place = c(rep("HIC", 6), rep("LMIC", 6)),
  pathogen = rep(c("FLU", "FLU", "FLU", "SC2", "SC2", "SC2"), 2),
  intervention = rep(c("vax_older", "vax_working", "vax_young"), 4),
  pct_overestimate = c(
    55.9, 24.7, 31.5,
    45.7, 24.2, 39.9,
    164.0, 39.7, 54.0,
    173.0, 20.4, 96.3
  )
)

published_yll <- data.table(
  place = c(rep("HIC", 3), rep("LMIC", 3), rep("HIC", 3), rep("LMIC", 3)),
  pathogen = c(rep("FLU", 6), rep("SC2", 6)),
  intervention = rep(c("vax_older", "vax_working", "vax_young"), 4),
  pct_overestimate = c(
    76.5, 47.8, 38.8,
    52.3, 42.8, 26.2,
    99.0, 73.4, 77.1,
    65.1, 89.0, 46.4
  )
)

calc_ifr <- ifr_dt[, .(
  place,
  pathogen,
  pct_calc = signif(100 * (wm_f - f_mean) / f_mean, 3)
)]
setkey(calc_ifr, place, pathogen)
setkey(published_ifr, place, pathogen)
comp_ifr <- merge(calc_ifr, published_ifr, by = c("place", "pathogen"))

calc_deaths <- melt_int_dt[, .(
  place,
  pathogen,
  intervention,
  pct_calc = pct_overestimate
)]
setkey(calc_deaths, place, pathogen, intervention)
setkey(published_deaths, place, pathogen, intervention)
comp_deaths <- merge(
  calc_deaths,
  published_deaths,
  by = c("place", "pathogen", "intervention")
)

calc_yll <- melt_yll_dt[, .(
  place,
  pathogen,
  intervention,
  pct_calc = pct_overestimate
)]
setkey(calc_yll, place, pathogen, intervention)
setkey(published_yll, place, pathogen, intervention)
comp_yll <- merge(
  calc_yll,
  published_yll,
  by = c("place", "pathogen", "intervention")
)

# Assert that all calculated numbers match published benchmarks
stopifnot(
  "Calculated 65+ IFR increases do not match published benchmarks" =
    isTRUE(all.equal(comp_ifr$pct_calc, comp_ifr$pct_increase))
)
stopifnot(
  "Calculated averted death overestimates do not match published benchmarks" =
    isTRUE(all.equal(comp_deaths$pct_calc, comp_deaths$pct_overestimate))
)
stopifnot(
  "Calculated averted YLL overestimates do not match published benchmarks" =
    isTRUE(all.equal(comp_yll$pct_calc, comp_yll$pct_overestimate))
)

cat(
  "\n==> Numerical verification successful:",
  "all results match published benchmarks.\n"
)

out_file <- file.path(dirname(.args[5]), "benchmark_comparison.rds")
saveRDS(list(
  ifr = comp_ifr,
  deaths = comp_deaths,
  yll = comp_yll
), out_file)
