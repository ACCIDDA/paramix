check_not_numeric <- function(var, name = deparse(substitute(var)), n = 1L) {
  stop_fmt_if(
    !is.numeric(var),
    ERR_PARTITION_NOT_NUMERIC,
    name = name,
    n = n + 1L
  )
  stop_fmt_if(
    any(is.na(var)),
    ERR_PARTITION_HAS_NA,
    name = name,
    n = n + 1L
  )
}

check_sorted <- function(var, name = deparse(substitute(var)), n = 1L) {
  if (
    warn_fmt_if(
      is.unsorted(var),
      MSG_PARTITION_NOT_SORTED,
      name = name,
      values = toString(var),
      n = n + 1L
    )
  ) {
    sort(var)
  } else {
    var
  }
}

check_unique <- function(var, name = deparse(substitute(var)), n = 1L) {
  ret <- unique(var)
  warn_fmt_if(
    length(ret) != length(var),
    MSG_PARTITION_NOT_UNIQUE,
    name = name,
    values = toString(var),
    n = n + 1L
  )
  ret
}

check_bound <- function(vlen, var, res, what, name = deparse(substitute(var))) {
  wtf <- switch(
    what,
    lower = utils::head,
    upper = utils::tail
  )

  if (vlen > 0L) {
    var_bound <- wtf(var, 1L)
    res_bound <- wtf(res, 1L)
    if (var_bound != res_bound) {
      sprintf(
        "`%s` %s bound does not match mixture: %s vs %s",
        name,
        what,
        toString(var_bound),
        toString(res_bound)
      )
    }
  }
}

#' @title Create a Least-Common-Interval Partition
#'
#' @description
#' Internal utility method for creating partitions, possibly from multiple
#' distinct partitions. Validates inputs.
#'
#' @param model_partition the model partition
#'
#' @param output_partition the output partition
#'
#' @return a sorted numeric vector with unique values
#' @keywords internal
#' @noRd
make_partition <- function(
  model_partition = numeric(0),
  output_partition = numeric(0)
) {
  check_not_numeric(model_partition)
  check_not_numeric(output_partition)

  mlen <- length(model_partition)
  olen <- length(output_partition)

  stop_fmt_if(
    mlen + olen == 0L,
    ERR_PARTITION_BOTH_EMPTY
  )

  model_partition <- check_sorted(model_partition)
  model_partition <- check_unique(model_partition)
  output_partition <- check_sorted(output_partition)
  output_partition <- check_unique(output_partition)

  res <- unique(sort(c(model_partition, output_partition)))

  checked_bounds <- c(
    check_bound(mlen, model_partition, res, "lower"),
    check_bound(mlen, model_partition, res, "upper"),
    check_bound(olen, output_partition, res, "lower"),
    check_bound(olen, output_partition, res, "upper")
  )

  stop_fmt_if(
    !is.null(checked_bounds),
    ERR_PARTITION_BOUNDS_MISMATCH,
    details = paste(checked_bounds, collapse = "\n\t")
  )

  res
}

sanitize_data <- function(x, bounds) {
  stop_fmt_if(
    ncol(x) < 2L,
    ERR_DATA_MIN_COLS
  )
  warn_fmt_if(
    ncol(x) > 2L,
    MSG_DATA_EXTRA_COLS,
    cols = toString(names(x)[1:2])
  )
  x <- x[, c(1, 2)]
  classes_str <- paste(
    toString(class(x[[1]])),
    toString(class(x[[2]])),
    sep = ", "
  )
  stop_fmt_if(
    !is.numeric(x[[1]]) || !is.numeric(x[[2]]),
    ERR_DATA_COLS_NOT_NUMERIC,
    classes = classes_str
  )
  if (
    warn_fmt_if(
      is.unsorted(x[[1]]),
      MSG_DATA_COL1_UNSORTED,
      values = toString(x[[1]])
    )
  ) {
    x <- x[order(x[[1]]), ]
  }
  warn_fmt_if(
    bounds[1] < x[[1]][1],
    MSG_DATA_LOWER_BOUND_OOB,
    bound = bounds[1],
    entry = x[[1]][1]
  )
  warn_fmt_if(
    bounds[2] > utils::tail(x[[1]], 1L),
    MSG_DATA_UPPER_BOUND_OOB,
    bound = bounds[2],
    entry = utils::tail(x[[1]], 1L)
  )
  warn_fmt_if(
    length(unique(x[[1]])) != nrow(x),
    MSG_DATA_COL1_NOT_UNIQUE,
    values = toString(x[[1]])
  )
  x
}

#' @title Internal Conversion of Data to Function
#'
#' @param x a function or the single argument version of `x` in
#' [xy.coords()] (as per [approxfun()] or [splinefun()] inputs). Pass through
#' from user input, must be checked
#'
#' @param bounds numeric vector, length 2: the partition lower bound; not checked,
#' result of `range(make_partition(...))`.
#'
#' @param interp_opts if `x` is function, ignored. Otherwise,
#' an interpolating function and its arguments.
#'
#' @return a function
#' @keywords internal
#' @noRd
to_function <- function(x, bounds, interp_opts) {
  if (is.function(x)) {
    bcheck <- c(x(bounds[1]), x(bounds[2]))
    stop_fmt_if(
      any(is.na(bcheck)),
      ERR_TO_FUNCTION_BOUNDS_NA,
      lb = toString(bcheck[1]),
      ub = toString(bcheck[2]),
      fn = deparse(substitute(x))
    )
    x
  } else if (is.data.frame(x)) {
    x <- sanitize_data(x, bounds)

    callargs <- do.call(interpolate_opts, interp_opts)
    callfun <- interp_opts$fun
    callargs$fun <- NULL
    if (!callargs$.usekind) {
      kind <- callargs$kind
      callargs$kind <- NULL
      if (kind == "integral") {
        len <- length(x[[2]])
        stop_fmt_if(
          x[[2]][len] != 0,
          ERR_INTEGRAL_FINAL_NOT_ZERO,
          val = toString(x[[2]][len])
        )
        ws <- diff(x[[1]])
        x[[2]] <- c(x[[2]][-len] / ws, 0)
      }
    }
    callargs$.usekind <- NULL
    callargs$x <- x
    do.call(callfun, args = callargs)
  } else {
    stop_fmt_if(
      TRUE,
      ERR_TO_FUNCTION_TYPE,
      name = deparse(substitute(x)),
      type = toString(class(x))
    )
  }
}

#' @title Compose Parameter & Density Functions
#'
#' @description
#' Purely internal, called after `to_function`, so no direct user arguments.#'
#'
#' @param f_param a function; the parameter function, varying with the aggregate
#'
#' @param f_pop a function; the density function, varying with the aggregate
#'
#' @return a new function, f(x) = f_param(x)*f_pop(x)
#'
#' @keywords internal
#' @noRd
make_weight <- function(f_param, f_pop) {
  function(x) f_param(x) * f_pop(x)
}
