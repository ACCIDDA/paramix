# ==============================================================================
# Centralized Error and Warning Messages, Formatting, and Signaling Infrastructure
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Message Formatting and Signaling Functions
# ------------------------------------------------------------------------------

#' @title Format a message string with named placeholders or sprintf specifiers
#'
#' @description
#' Formats a template string. If named arguments are provided and `{name}`
#' placeholders exist in `fmt`, `{name}` tokens are replaced with matching argument values.
#' Otherwise, arguments are forwarded to [sprintf()].
#'
#' @param fmt character template string.
#' @param ... values to interpolate.
#' @param width integer maximum width for vector formatting via `toString()` (default: `80L`).
#'
#' @return a character scalar, the formatted message.
#'
#' @keywords internal
#' @noRd
format_message <- function(fmt, ..., width = 80L) {
  args <- list(...)
  if (length(args) == 0L) {
    fmt
  } else {
    arg_names <- names(args)
    if (!is.null(arg_names) && any(nzchar(arg_names))) {
      for (i in seq_along(args)) {
        nm <- arg_names[i]
        if (nzchar(nm)) {
          fmt <- gsub(
            paste0("{", nm, "}"),
            toString(args[[i]], width = width),
            fmt,
            fixed = TRUE
          )
        }
      }
      fmt
    } else {
      sprintf(fmt, ...)
    }
  }
}

#' @title Construct a paramix validation condition
#'
#' @description
#' Builds an error or warning condition carrying structured data alongside its
#' message, so callers can read fields instead of parsing message text.
#'
#' @param type character scalar; 'error' or 'warning'.
#' @param message character scalar; the formatted condition message.
#' @param id character scalar; the name of the message template (e.g.
#'   `"ERR_PARTITION_NOT_NUMERIC"`), or `NA` if unknown.
#' @param fields a named list of additional fields to attach (default: `list()`).
#' @param call the call to attribute the condition to (default: `NULL`).
#'
#' @return a condition of class `paramix_error` or `paramix_warning`, also
#'   inheriting from `error` or `warning`, with elements `message`, `call`,
#'   `id`, and `fields`. Non-reserved fields are also available directly on the
#'   condition.
#'
#' @keywords internal
#' @noRd
paramix_condition <- function(type, message, id, fields = list(), call = NULL) {
  type <- match.arg(type, c("error", "warning"))
  reserved <- c("message", "call", "id", "fields")
  direct_fields <- fields[!names(fields) %in% reserved]
  structure(
    c(
      list(message = message, call = call, id = id, fields = fields),
      direct_fields
    ),
    class = c(paste0("paramix_", type), type, "condition")
  )
}

#' @title Signal an error if a condition is met with formatted message
#'
#' @description
#' Evaluates `cond` and if `TRUE`, raises a `paramix_error` formatted with
#' `format_message()`. The error's `id` is the name of the template passed as
#' `fmt`, and each named argument in `...` is attached as a field with its raw
#' value.
#'
#' @param cond logical expression to evaluate.
#' @param fmt character format string, passed as a template constant so its
#'   name can be recorded as the error `id`.
#' @param ... additional arguments passed to `format_message()`.
#' @param n frame offset integer specifying call stack depth for call attribution
#'   (default: `1L`). If `n <= 0L`, call attribution is suppressed (`NULL`).
#'
#' @keywords internal
#' @noRd
stop_fmt_if <- function(cond, fmt, ..., n = 1L) {
  if (isTRUE(cond)) {
    call_obj <- if (n > 0L && sys.nframe() >= n) sys.call(-n) else NULL
    fmt_expr <- substitute(fmt)
    id <- if (is.name(fmt_expr)) as.character(fmt_expr) else NA_character_
    args <- list(...)
    fields <- if (is.null(names(args))) list() else args[nzchar(names(args))]
    stop(paramix_condition(
      "error",
      format_message(fmt, ...),
      id,
      fields,
      call_obj
    ))
  }
}

#' @title Signal a warning if a condition is met with formatted message
#'
#' @description
#' Evaluates `cond` and if `TRUE`, signals a `paramix_warning` formatted with
#' `format_message()`. The template name is recorded as `id`, and named
#' arguments in `...` are attached as raw fields.
#'
#' @param cond logical expression to evaluate.
#' @param fmt character format string, passed as a template constant so its
#'   name can be recorded as the warning `id`.
#' @param ... additional arguments passed to `format_message()`.
#' @param n frame offset integer specifying call stack depth for call attribution
#'   (default: `1L`). If `n <= 0L`, call attribution is suppressed (`NULL`).
#'
#' @return a logical scalar, indicating whether `cond` evaluated to `TRUE`.
#'
#' @keywords internal
#' @noRd
warn_fmt_if <- function(cond, fmt, ..., n = 1L) {
  cond_val <- isTRUE(cond)
  if (cond_val) {
    call_obj <- if (n > 0L && sys.nframe() >= n) sys.call(-n) else NULL
    fmt_expr <- substitute(fmt)
    id <- if (is.name(fmt_expr)) as.character(fmt_expr) else NA_character_
    args <- list(...)
    fields <- if (is.null(names(args))) list() else args[nzchar(names(args))]
    warning(paramix_condition(
      "warning",
      format_message(fmt, ...),
      id,
      fields,
      call_obj
    ))
  }
  cond_val
}

# ------------------------------------------------------------------------------
# 2. Partition Validation Templates
# ------------------------------------------------------------------------------

ERR_PARTITION_NOT_NUMERIC <- "`{name}` is not numeric"
ERR_PARTITION_HAS_NA <- "`{name}` contains NA/NaN values"
ERR_PARTITION_BOTH_EMPTY <- "`model_partition` and `output_partition` cannot both be empty."

ERR_PARTITION_BOUNDS_MISMATCH <- paste0(
  "Partition boundaries must match. If these partitions are correct, ",
  "for example if the output partitions drop results from the total ",
  "simulated population, consider supplying a dummy partition and ",
  "then discarding it.\n\t{details}"
)

MSG_PARTITION_NOT_SORTED <- "`{name}` is not sorted: {values}"
MSG_PARTITION_NOT_UNIQUE <- "`{name}` is not unique: {values}"

# ------------------------------------------------------------------------------
# 3. Data Sanitization & Interpolation Templates
# ------------------------------------------------------------------------------

ERR_DATA_MIN_COLS <- "data must have at least two columns."
MSG_DATA_EXTRA_COLS <- "data has more than two columns; only using {cols}"
ERR_DATA_COLS_NOT_NUMERIC <- paste0(
  "first two data columns must satisfy is.numeric; got classes {classes}"
)
MSG_DATA_COL1_UNSORTED <- paste0(
  "data column 1 is unsorted: {values}; will be sorted before interpolation"
)
MSG_DATA_LOWER_BOUND_OOB <- paste0(
  "data may not support bounds: lower bound {bound} < first column 1 entry {entry}"
)
MSG_DATA_UPPER_BOUND_OOB <- paste0(
  "data may not support bounds: upper bound {bound} > last column 1 entry {entry}"
)
MSG_DATA_COL1_NOT_UNIQUE <- paste0(
  "data column 1 is not unique: {values}; ensure interpolation function can handle this."
)

ERR_TO_FUNCTION_BOUNDS_NA <- paste0(
  "The (lower, upper) bounds of the mixing partition evaluate to ",
  "({lb}, {ub}); the function {fn} must be defined on the whole partition."
)
ERR_INTEGRAL_FINAL_NOT_ZERO <- paste0(
  "for integral data, the final entry should be 0; got instead: {val}"
)
ERR_TO_FUNCTION_TYPE <- "{name} must be a function or data.frame; received {type}."

ERR_INTERP_NOT_FUNCTION <- "{name} is not a function."
ERR_INTERP_FUN_NO_ARGS <- "`fun` must have at least one argument."
ERR_INTERP_NEWARGS_UNNAMED <- "If provided via `...` additional new args must be named."
ERR_INTERP_INVALID_ARGS <- paste0(
  "Provided arguments not present in {name} signature: {extra} ",
  "(signature arguments are {sig})"
)
ERR_INTERP_FIRST_ARG_RESERVED <- paste0(
  "The first argument to `fun` is where the data will be sent; ",
  "cannot provide {first_arg} via `...`"
)

# ------------------------------------------------------------------------------
# 4. Outcome Distillation Templates
# ------------------------------------------------------------------------------

ERR_OUTCOMES_EXTRA_GROUPS <- paste0(
  "`outcomes_dt[['{groupcol}']]` has groups not present in ",
  "`alembic_dt$model_partition`: {groups}"
)
MSG_OUTCOMES_MISSING_GROUPS <- paste0(
  "`outcomes_dt[['{groupcol}']]` does not cover the groups present in ",
  "`alembic_dt$model_partition`: missing {groups}"
)
