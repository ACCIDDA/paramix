# Distill Outcomes

`distill` takes a low-age resolution outcome, for example deaths, and
proportionally distributes that outcome into a higher age resolution for
use in subsequent analyses like years-life-lost style calculations.

## Usage

``` r
distill(alembic_dt, outcomes_dt, groupcol = names(outcomes_dt)[1])
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

a `data.frame`, with `output_partition` and recalculated `value` column

## Details

When the `value` column is re-calculated, note that it will aggregate
all rows with matching `groupcol` entries in `outcomes_dt`. If you need
to group by other features in your input data (e.g. if you need to
distill outcomes across multiple simulation outputs or at multiple time
points), that has to be done by external grouping then calling
`distill()`.

## Examples

``` r

ifr_levin <- function(age_in_years) {
  (10^(-3.27 + 0.0524 * age_in_years))/100
}

age_limits <- c(seq(0, 69, by = 5), 70, 80, 101)
age_pyramid <- data.frame(
  from = 0:101, weight = ifelse(0:101 < 65, 1, .99^(0:101-64))
)
age_pyramid$weight[102] <- 0
# flat age distribution, then 1% annual deaths, no one lives past 101

alembic_dt <- alembic(ifr_levin, age_pyramid, age_limits, 0:101)

results <- data.frame(model_partition = head(age_limits, -1))
results$value <- 10
distill(alembic_dt, results)
#>      output_partition     value
#>                 <int>     <num>
#>   1:                0 1.5485580
#>   2:                1 1.7471391
#>   3:                2 1.9711854
#>   4:                3 2.2239626
#>   5:                4 2.5091549
#>  ---                           
#>  97:               96 0.7458225
#>  98:               97 0.8330492
#>  99:               98 0.9304775
#> 100:               99 1.0393003
#> 101:              100 1.1608504
```
