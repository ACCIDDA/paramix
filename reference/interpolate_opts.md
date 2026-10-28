# Interpolation Options

Creates and interpolation options object for use with
[`alembic()`](https://accidda.github.io/paramix/reference/alembic.md).

## Usage

``` r
interpolate_opts(fun, kind = c("point", "integral"), ...)
```

## Arguments

- fun:

  a function

- kind:

  a string; either "point" or "integral". How to interpret the x, y
  values being interpolated. Either as point observations of a function
  OR as the integral of the function over the interval.

- ...:

  arbitrary other arguments, but checked against signature of `fun`

## Value

a list, with `fun` and `kind` keys, as well as whatever other valid keys
appear in `...`.

## Details

This method creates the interpolation object for use with
[`alembic()`](https://accidda.github.io/paramix/reference/alembic.md);
this is a convenience method, which does basic validation on arguments
and ensures the information used in
[`alembic()`](https://accidda.github.io/paramix/reference/alembic.md) to
do interpolation is available.

The `...` arguments will be provided to `fun` when it is invoked to
interpolate the tabular "functional" form of arguments to
[`alembic()`](https://accidda.github.io/paramix/reference/alembic.md).
If `fun` has an argument `kind`, that parameter will also be passed when
invoking the function; if not, then the input data will be transformed
to \\\\x, z\\\\ pairs, such that \\x\_{i+1}-x\_{i} \* z_i = y_i\\ -
i.e., transforming to a point value and a functional form which is
assumed constant until the next partition.

## Examples

``` r
interpolate_opts(
  fun = stats::splinefun, method = "natural", kind = "point"
)
#> $fun
#> function (x, y = NULL, method = c("fmm", "periodic", "natural", 
#>     "monoH.FC", "hyman"), ties = mean) 
#> {
#>     x <- regularize.values(x, y, ties, missing(ties))
#>     y <- x$y
#>     x <- x$x
#>     nx <- length(x)
#>     if (is.na(nx)) 
#>         stop(gettextf("invalid value of %s", "length(x)"), domain = NA)
#>     if (nx == 0) 
#>         stop("zero non-NA points")
#>     method <- match.arg(method)
#>     if (method == "periodic" && y[1L] != y[nx]) {
#>         warning("spline: first and last y values differ - using y[1L] for both")
#>         y[nx] <- y[1L]
#>     }
#>     if (method == "monoH.FC") {
#>         n1 <- nx - 1L
#>         dy <- y[-1L] - y[-nx]
#>         dx <- x[-1L] - x[-nx]
#>         Sx <- dy/dx
#>         m <- c(Sx[1L], (Sx[-1L] + Sx[-n1])/2, Sx[n1])
#>         m <- .Call(C_monoFC_m, m, Sx)
#>         return(splinefunH0(x0 = x, y0 = y, m = m, dx = dx))
#>     }
#>     iMeth <- match(method, c("periodic", "natural", "fmm", "monoH.FC", 
#>         "hyman"))
#>     if (iMeth == 5L) {
#>         dy <- diff(y)
#>         if (!(all(dy >= 0) || all(dy <= 0))) 
#>             stop("'y' must be increasing or decreasing")
#>     }
#>     z <- .Call(C_SplineCoef, min(3L, iMeth), x, y)
#>     if (iMeth == 5L) 
#>         z <- spl_coef_conv(hyman_filter(z))
#>     rm(x, y, nx, method, iMeth, ties)
#>     function(x, deriv = 0L) {
#>         deriv <- as.integer(deriv)
#>         if (deriv < 0L || deriv > 3L) 
#>             stop("'deriv' must be between 0 and 3")
#>         if (deriv > 0L) {
#>             z0 <- double(z$n)
#>             z[c("y", "b", "c")] <- switch(deriv, list(y = z$b, 
#>                 b = 2 * z$c, c = 3 * z$d), list(y = 2 * z$c, 
#>                 b = 6 * z$d, c = z0), list(y = 6 * z$d, b = z0, 
#>                 c = z0))
#>             z[["d"]] <- z0
#>         }
#>         res <- .splinefun(x, z)
#>         if (deriv > 0 && z$method == 2 && any(ind <- x <= z$x[1L])) 
#>             res[ind] <- ifelse(deriv == 1, z$y[1L], 0)
#>         res
#>     }
#> }
#> <bytecode: 0x56305f91ce88>
#> <environment: namespace:stats>
#> 
#> $kind
#> [1] "point"
#> 
#> $.usekind
#> [1] FALSE
#> 
#> $method
#> [1] "natural"
#> 
interpolate_opts(
  fun = stats::approxfun, method = "constant", yleft = 0, yright = 0,
  kind = "integral"
)
#> $fun
#> function (x, y = NULL, method = "linear", yleft, yright, rule = 1, 
#>     f = 0, ties = mean, na.rm = TRUE) 
#> {
#>     method <- pmatch(method, c("linear", "constant"))
#>     if (is.na(method)) 
#>         stop("invalid interpolation method")
#>     stopifnot(is.numeric(rule), (lenR <- length(rule)) >= 1L, 
#>         lenR <= 2L)
#>     if (lenR == 1) 
#>         rule <- rule[c(1, 1)]
#>     x <- regularize.values(x, y, ties, missing(ties), na.rm = na.rm)
#>     nx <- if (na.rm || !x$keptNA) 
#>         length(x$x)
#>     else sum(x$notNA)
#>     if (is.na(nx)) 
#>         stop("invalid length(x)")
#>     if (nx <= 1) {
#>         if (method == 1) 
#>             stop("need at least two non-NA values to interpolate")
#>         if (nx == 0) 
#>             stop("zero non-NA points")
#>     }
#>     y <- x$y
#>     if (missing(yleft)) 
#>         yleft <- if (rule[1L] == 1) 
#>             NA
#>         else y[1L]
#>     if (missing(yright)) 
#>         yright <- if (rule[2L] == 1) 
#>             NA
#>         else y[length(y)]
#>     stopifnot(length(yleft) == 1L, length(yright) == 1L, length(f) == 
#>         1L)
#>     rm(rule, ties, lenR, nx)
#>     x <- as.double(x$x)
#>     y <- as.double(y)
#>     .Call(C_ApproxTest, x, y, method, f, na.rm)
#>     function(v) .approxfun(x, y, v, method, yleft, yright, f, 
#>         na.rm)
#> }
#> <bytecode: 0x56305fe62240>
#> <environment: namespace:stats>
#> 
#> $kind
#> [1] "integral"
#> 
#> $.usekind
#> [1] FALSE
#> 
#> $method
#> [1] "constant"
#> 
#> $yleft
#> [1] 0
#> 
#> $yright
#> [1] 0
#> 
```
