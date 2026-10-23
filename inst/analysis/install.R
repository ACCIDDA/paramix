options(renv.consent = TRUE)
stopifnot("Must have `renv` installed." = require(renv))

# Ensure host library paths (including where paramix is installed) are accessible
host_libs <- .libPaths()
renv::settings$external.libraries(
  unique(c(renv::settings$external.libraries(), host_libs)),
  persist = TRUE
)

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
