## Test environments
* Local: Ubuntu 25.04, R 4.5.1
* GitHub Actions:
  * Ubuntu (release, oldrel, devel)
  * macOS (release)
  * Windows (release)

## R CMD check results

0 errors | 0 warnings | 0 notes

## Release summary (0.0.2)

This release provides documentation enhancements, build infrastructure improvements, and code quality updates:

* Extended and clarified mathematical formulations in roxygen documentation and vignettes.
* Integrated package logo and generated favicons for pkgdown documentation.
* Standardized error and warning messages with centralized formatting and dedicated unit tests.
* Modernized build infrastructure using `justfile`, automated formatting with `air`, and comprehensive `lintr` rules.
* Updated CI pipelines to multi-platform checks (Linux, macOS, Windows) and automated documentation deployment.
* Removed generated documentation (`man/*.Rd`) and intermediate vignette render files from version control, managing them dynamically through `roxygen2` and `roxyglobals`.
