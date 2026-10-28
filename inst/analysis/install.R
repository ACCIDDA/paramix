options(renv.consent = TRUE)
options(timeout = max(600, getOption("timeout")))
stopifnot("Must have `renv` installed." = require(renv))

# Ensure host library paths (including where paramix is installed) are accessible
host_libs <- .libPaths()
renv::settings$external.libraries(
  unique(c(renv::settings$external.libraries(), host_libs)),
  persist = TRUE
)

# If host environment has configured package repositories (e.g. PPM), allow
# renv to use them
repos <- getOption("repos")
if (!is.null(repos) && length(repos) > 0 && !any(repos == "@CRAN@")) {
  options(renv.config.repos.override = repos)
}

renv::activate()

# Restore analysis dependencies from renv.lock, excluding paramix which is
# supplied via external host library from the local package build
res <- renv::restore(exclude = "paramix", prompt = FALSE)

if (exists("res")) {
  print(res)
}
