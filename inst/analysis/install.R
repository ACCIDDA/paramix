options(renv.consent = TRUE)
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
