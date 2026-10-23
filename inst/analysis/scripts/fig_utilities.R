require(ggplot2)

# the `trap` pattern here let's us source this file interactively
# without having to rm(list = ls()) to avoid leaking unwanted objects into
# our resulting file

.args <- if (interactive()) {
  c(
    file.path("figure", "fig_utilities.rda")
  )
} else {
  commandArgs(trailingOnly = TRUE)
}

#' Generic Function Wrapper
#'
#' @description provides a convenience function for
#' producing duplicate functions with different
#' defaults
#'
#' @param FUN the function to wrap
#'
#' @param ... the new defaults
#'
#' @param .ENV the environment for the resulting
#' copy-function (i.e. where any variables will be
#' evaluated). NB, the default (`environment(FUN)`) is
#' mostly convenient, but can be dangerous e.g. by
#' replacing an important function
#'
#'
#' @return the new function
rejig <- function(fn, ..., env = environment(fn)) {
  # initial validation
  stopifnot(
    "fn isn't a function." = is.function(fn),
    "fn is a primitive function." = !is.primitive(fn)
  )

  dots <- as.list(match.call())[-1] # get some new defaults
  dots$fn <- dots$env <- NULL # drop all the not-defaults

  if (length(dots) == 0) {
    warning("... is empty. Just returning fn.")
    return(fn)
  }

  fn_copy <- fn # make a duplicate of fn
  forms <- formals(fn) # get the original defaults

  # potentially more validation: check for ... argument
  # in fn and try to partial match all arguments in
  # rejig
  hasdots <- "..." %in% names(forms)
  replacements <- names(forms)[pmatch(names(dots), names(forms))]

  if (any(is.na(replacements)) && !hasdots) {
    errmsg <- sprintf(
      "
fn does not have ... argument, and
rejig ... arguments do not match fn arguments:
%s
",
      names(dots)[is.na(replacements)] |> paste(collapse = ", ")
    )
    stop(errmsg)
  }

  match_call_defaults <- function(
    definition = sys.function(sys.parent()),
    call = sys.call(sys.parent()),
    expand_dots = TRUE,
    envir = parent.frame(2L)
  ) {
    # get the call
    mc <- match.call(definition, call, expand_dots, envir)
    # get the formals, tossing any ellipsis
    fs <- formals(definition, envir)
    fs$... <- NULL

    # for any arguments set in formals & not in the call
    for (nm in setdiff(names(fs), names(mc))) {
      mc[nm] <- fs[nm]
    } # add those to the call

    mc
  }

  # correct any partially matched defaults
  names(dots)[!is.na(replacements)] <- replacements[!is.na(replacements)]
  # set the new defaults
  formals(fn_copy)[names(dots)] <- dots
  environment(fn_copy) <- env

  if (hasdots && any(is.na(replacements))) {
    # the internals of fn may pass around the ellipsis, which now
    # excludes newly set default variables, so need to use it
    body(fn_copy) <- substitute({
      mc <- match_call_defaults()
      mc[[1]] <- fn
      eval(mc)
    })
  }

  fn_copy
}

trap <- function(.target) {
  from_labels <- c(
    "0" = "0-4",
    "5" = "5-19",
    "20" = "20-64",
    "65" = "65+"
  )

  age_group_labels <- from_labels |> setNames(1:4)

  iso_labels <- c(AFG = "LMIC-like", GBR = "HIC-like")

  intervention_labels <- from_labels |>
    setNames(c("none", paste0("vax_", c("young", "working", "older"))))
  intervention_labels[1] <- "Nobody"
  # selected using colorbrewer2.org:
  # https://colorbrewer2.org/#type=sequential&scheme=GnBu&n=5
  intervention_cols <- c("black", "#fecc5c", "#fd8d3c", "#d7191c") |>
    setNames(names(intervention_labels))

  pathogen_labels <- c(FLU = "Flu-like", SC2 = "COVID-like")

  model_assumption_labels <- c(
    f_mid = "IFR(mid(Age))",
    f_mean = "IFR(E[Age])",
    mean_f = "unused",
    wm_f = "paramix",
    f_val = "IFR(age)",
    full = "High resolution"
  )
  model_assumption_cols <- c(
    "#d01c8b",
    "#f1b6da",
    "#b8e186",
    "#4dac26",
    "black",
    "grey25"
  ) |>
    setNames(names(model_assumption_labels))

  distill_assumption_labels <- c(
    "Uniform",
    "Mean age",
    "Prop. to\npop. density",
    "paramix",
    "unused",
    "High resolution"
  ) |>
    setNames(names(model_assumption_labels))

  model_cols <- c(
    "#fed976",
    "#feb24c",
    "black",
    "#f03b20",
    "#fd8d3c",
    "#bd0026"
  ) |>
    setNames(names(model_assumption_labels))

  distill_cols <- c(
    "#fed976",
    "#feb24c",
    "#fd8d3c",
    "#f03b20",
    "black",
    "#bd0026"
  ) |>
    setNames(names(distill_assumption_labels))

  scale_color_intervention <- rejig(
    scale_color_manual,
    name = "Vaccinate ",
    breaks = names(intervention_labels),
    labels = intervention_labels,
    values = intervention_cols,
    aesthetics = c("color", "fill")
  )

  scale_color_model <- rejig(
    scale_color_manual,
    name = "Approach",
    breaks = names(model_assumption_labels),
    labels = model_assumption_labels,
    values = model_cols,
    aesthetics = c("color", "fill")
  )

  scale_color_distill <- rejig(
    scale_color_manual,
    name = "Approach",
    breaks = names(distill_assumption_labels),
    labels = distill_assumption_labels,
    values = distill_cols,
    aesthetics = c("color", "fill")
  )

  scale_x_simtime <- rejig(
    scale_x_continuous,
    name = "Simulation Time (weeks)",
    breaks = \(lims) seq(0, lims[2], by = 7),
    labels = \(b) b / 7,
    expand = expansion()
  )

  scale_linetype_pathogen <- rejig(
    scale_linetype_discrete,
    name = "Pathogen",
    labels = pathogen_labels
  )

  facet_iso <- rejig(
    facet_grid,
    cols = vars(iso3),
    labeller = ggplot2::labeller(iso3 = iso_labels)
  )

  save(list = ls(all.names = FALSE), file = .target)
}

trap(.args[1])
