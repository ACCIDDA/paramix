# Distillation Calculation Comparison Summary

Implements several approaches to imputing higher resolution outcomes,
then tables them up for convenient plotting.

## Usage

``` r
distill_summary(alembic_dt, outcomes_dt, groupcol = names(outcomes_dt)[1])
```

## Arguments

- alembic_dt:

  an
  [`alembic()`](https://accidda.github.io/paramix/reference/alembic.md)
  return value

- outcomes_dt:

  a long-format `data.frame` with a column either named `from` or
  `model_from` and a column `value` (other columns will be silently
  ignored)

- groupcol:

  a string, the name of the outcome model group column. The
  `outcomes_dt[[groupcol]]` column must match the `model_partition`
  lower bounds, as provided when constructing the `alembic_dt` with
  [`alembic()`](https://accidda.github.io/paramix/reference/alembic.md).

## Value

a `data.table`, columns:

- `partition`, the feature point corresponding to the value

- `value`, the translated `outcomes_dt$value`

- `method`, a factor with levels indicating how feature points are
  selected, and how `value` is weighted to those features:

  - `f_mid`: features at the `alembic_dt` outcome partitions, each with
    value corresponding to the total value of the corresponding model
    partition, divided by the number of outcome partitions in that model
    partition

  - `f_mean`: the features at the model partition means

  - `mean_f`: the features distributed according to the relative density
    in the outcome partitions

  - `wm_f`: the
    [`alembic()`](https://accidda.github.io/paramix/reference/alembic.md)
    approach

## Examples

``` r

library(data.table)
f_param <- function(age_in_years) {
  (10^(-3.27 + 0.0524 * age_in_years))/100
}

model_partition <- c(0, 5, 20, 65, 101)
density_dt <- data.table(
  from = 0:101, weight = c(rep(1, 66), exp(-0.075 * 1:35), 0)
)
alembic_dt <- alembic(
  f_param, density_dt, model_partition, seq(0, 101, by = 1L)
)

# for simplicity, assume a uniform force-of-infection across ages =>
# infections proportion to population density.
model_outcomes_dt <- density_dt[from != max(from), .(value = sum(f_param(from) * weight)),
  by = .(model_from = model_partition[findInterval(from, model_partition)])
]

ds_dt <- distill_summary(alembic_dt, model_outcomes_dt)
```
