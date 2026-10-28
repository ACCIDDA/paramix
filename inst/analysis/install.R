options(renv.consent = TRUE)
options(timeout = max(600, getOption("timeout")))
stopifnot("Must have `renv` installed." = require(renv))

# Ensure host library paths (including where paramix is installed) are accessible
host_libs <- .libPaths()
renv::settings$external.libraries(
  unique(c(renv::settings$external.libraries(), host_libs)),
  persist = TRUE
)

# If host environment has configured package repositories (e.g. PPM), allow renv to use them
repos <- getOption("repos")
if (!is.null(repos) && length(repos) > 0 && !any(repos == "@CRAN@")) {
  options(renv.config.repos.override = repos)
}

renv::activate()

# Verify whether required analysis packages are available in library paths
analysis_pkgs <- c(
  "data.table",
  "countrycode",
  "wpp2022",
  "odin",
  "socialmixr",
  "ggh4x",
  "ggplot2",
  "patchwork",
  "paramix"
)
missing_pkgs <- analysis_pkgs[!vapply(
  analysis_pkgs,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]

if (length(missing_pkgs) > 0) {
  message(
    "Missing packages (",
    paste(missing_pkgs, collapse = ", "),
    "); restoring from lockfile..."
  )
  tryCatch(
    res <- renv::restore(prompt = FALSE),
    error = function(e) {
      warning(
        "renv::restore() did not complete fully; relying on host packages: ",
        conditionMessage(e)
      )
    }
  )

  if (exists("res")) {
    print(res)
  }
} else {
  message("All analysis dependencies already available in library paths.")
}
