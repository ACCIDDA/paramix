#' @title Interpolation Options
#'
#' @description
#' Creates and interpolation options object for use with [alembic()].
#'
#' @param fun a function
#'
#' @param kind a string; either "point" or "integral". How to interpret the
#' x, y values being interpolated. Either as point observations of a function OR
#' as the integral of the function over the interval.
#'
#' @param ... arbitrary other arguments, but checked against signature of `fun`
#'
#' @details
#' This method creates the interpolation object for use with [alembic()]; this
#' is a convenience method, which does basic validation on arguments and ensures
#' the information used in [alembic()] to do interpolation is available.
#'
#' The `...` arguments will be provided to `fun` when it is invoked to
#' interpolate the tabular "functional" form of arguments to [alembic()]. If
#' `fun` has an argument `kind`, that parameter will also be passed when
#' invoking the function; if not, then the input data will be transformed to
#' \eqn{\{x, z\}} pairs, such that \eqn{x_{i+1}-x_{i} * z_i = y_i} - i.e., transforming to
#' a point value and a functional form which is assumed constant until the next
#' partition.
#'
#' @return a list, with `fun` and `kind` keys, as well as whatever other valid
#' keys appear in `...`.
#'
#' @examples
#' interpolate_opts(
#'   fun = stats::splinefun, method = "natural", kind = "point"
#' )
#' interpolate_opts(
#'   fun = stats::approxfun, method = "constant", yleft = 0, yright = 0,
#'   kind = "integral"
#' )
#' @export
interpolate_opts <- function(fun, kind = c("point", "integral"), ...) {
  stop_fmt_if(
    !is.function(fun),
    ERR_INTERP_NOT_FUNCTION,
    name = deparse(substitute(fun))
  )

  kind <- match.arg(kind, c("point", "integral"))
  funargs <- formals(fun)
  stop_fmt_if(is.null(funargs), ERR_INTERP_FUN_NO_ARGS)
  newargs <- list(...)
  # for when interpolate_opts is do.call'd on interpolate_opts output
  newargs$.usekind <- NULL

  baseret <- list(fun = fun, kind = kind, .usekind = "kind" %in% names(funargs))

  if (length(newargs)) {
    stop_fmt_if(
      is.null(names(newargs)) || ("" %in% names(newargs)),
      ERR_INTERP_NEWARGS_UNNAMED
    )
    if (!("..." %in% names(funargs))) {
      stop_fmt_if(
        length(setdiff(names(newargs), names(funargs))) != 0L,
        ERR_INTERP_INVALID_ARGS,
        name = deparse(substitute(fun)),
        extra = toString(setdiff(names(newargs), names(funargs))),
        sig = toString(funargs)
      )
    }
    stop_fmt_if(
      names(funargs)[1] %in% names(newargs),
      ERR_INTERP_FIRST_ARG_RESERVED,
      first_arg = names(funargs)[1]
    )
    c(baseret, newargs)
  } else {
    baseret
  }
}
