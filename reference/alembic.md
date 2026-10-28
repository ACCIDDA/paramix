# Create the Blending and Distilling Object

Based on model and output partitions, create a mixing partition and
associated weights. That table of mixing values can be used to properly
discretize a continuously varying (or otherwise high resolution)
parameter to a relatively low resolution compartmental stratification,
and then subsequently allocate the low-resolution model outcomes into
the most likely high-resolution output partitions.

## Usage

``` r
alembic(
  f_param,
  f_pop,
  model_partition,
  output_partition,
  pars_interp_opts = interpolate_opts(fun = stats::splinefun, kind = "point", method =
    "natural"),
  pop_interp_opts = interpolate_opts(fun = stats::approxfun, kind = "integral", method =
    "constant", yleft = 0, yright = 0)
)
```

## Arguments

- f_param:

  a function, `f(x)` which transforms the feature (e.g. age), to yield
  the parameter values. Alternatively, a `data.frame` where the first
  column is the feature and the second is the parameter; see
  [`xy.coords()`](https://rdrr.io/r/grDevices/xy.coords.html) for
  details. If the latter, combined with `pars_interp_opts` to create a
  parameter function.

- f_pop:

  like `f_param`, either a density function (though it does not have to
  integrate to 1 like a pdf) or a `data.frame` of values. If the latter,
  it is treated as a series of populations within intervals, and then
  interpolated with `pop_interp_opts` to create a density function.

- model_partition:

  a numeric vector of cut points, which define the partitioning that
  will be used in the model; must be length \> 1

- output_partition:

  the partition of the underlying feature; must be length \> 1

- pars_interp_opts:

  a list, minimally with an element `fun`, corresponding to an
  interpolation function. Defaults to
  [`splinefun()`](https://rdrr.io/r/stats/splinefun.html) "natural"
  interpolation.

- pop_interp_opts:

  like `pars_interp_opts`, but for density. Defaults to
  [`approxfun()`](https://rdrr.io/r/stats/approxfun.html) "constant"
  interpolation.

## Value

a `data.table` with columns: `model_partition`, `output_partition`,
`weight` and `relpop`. The first two columns identify partition lower
bounds, for both the model and output, the other values are associated
with; the combination of `model_partition` and `output_partition` forms
a unique identifier, but individually they may appear multiple times.
Generally, this object is only useful as an input to the
[`blend()`](https://accidda.github.io/paramix/reference/blend.md) and
[`distill()`](https://accidda.github.io/paramix/reference/distill.md)
tools.

## Details

The `alembic` function creates a mixing table, which governs the
conversion between model and output partitions. The mixing table a
[`data.table::data.table()`](https://rdrr.io/pkg/data.table/man/data.table.html)
where each row corresponds to a mixing partition \\c_i\\, which is the
union of the model and output partitions - i.e. each unique boundary is
included. Within each row, there is a `weight` and `relpop` entry,
corresponding to

\$\$ \textrm{weight}\_i = \int\_{c_i} f(x)\rho(x)\text{d}x \$\$ \$\$
\textrm{relpop}\_i = \int\_{c_i} \rho(x)\text{d}x \$\$

where \\f(x)\\ corresponds to the `f_param` argument and \\\rho(x)\\
corresponds to the `f_pop` argument.

This mixing table is used in the
[`blend()`](https://accidda.github.io/paramix/reference/blend.md) and
[`distill()`](https://accidda.github.io/paramix/reference/distill.md)
functions.

When `blend`ing, the appropriately weighted parameter for a model
partition is the sum of \\\textrm{weight}\_i\\ divided by the
\\\textrm{relpop}\_i\\ associated with mixing partition(s) in that model
partition. This corresponds to the properly, population weighted average
of that parameter over the partition.

When `distill`ing, model outcomes associated with weighted parameter
from partition \\j\\ are distributed to the output partition \\i\\ by
the sum of weights in mixing partitions in both \\j\\ and \\i\\ divided
by the total weight in \\j\\. This corresponds to proportional
allocation according to Bayes rule: the outcome in the model partition
was relatively more likely in the higher weight mixing partition.

## See also

[`blend()`](https://accidda.github.io/paramix/reference/blend.md)

[`distill()`](https://accidda.github.io/paramix/reference/distill.md)

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
ifr_alembic <- alembic(ifr_levin, age_pyramid, age_limits, 0:101)
```
