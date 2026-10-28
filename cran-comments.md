## Test environments
* Local: Ubuntu 25.04, R 4.5.1
* GitHub Actions:
  * Ubuntu (release, oldrel, devel)
  * macOS (release)
  * Windows (release)

## R CMD check results

0 errors | 0 warnings | 0 notes

## Release summary (0.0.3)

This is a patch release providing documentation enhancements, centralized error signaling, reproducible paper analysis validation, and modernized build infrastructure.

### Documentation and Vignettes
* Added dedicated vignette `reproducing-paper-analysis` describing how to run the simulation study from Goodfellow et al. (2025) <doi:10.1371/journal.pcbi.1013420>, including numerical comparison tables against published benchmarks.
* Updated package citation metadata in `DESCRIPTION` and `inst/CITATION` for the published *PLOS Computational Biology* paper.
* Extended and clarified mathematical formulations in roxygen documentation and package vignettes.
* Added package hex logo and configured pkgdown favicons with light/dark theme support.
* Removed pre-rendered documentation and intermediate vignette assets from version control, managing them dynamically via `roxygen2`.

### Error Handling and Testing
* Centralized error and warning signaling into named format templates in `R/messages.R`.
* Added comprehensive unit test coverage for all input validation and signaling paths in `tests/testthat/test-messages.R`.

### Demonstration Analysis and Reproducibility
* Modernized the bundled simulation analysis in `inst/analysis/` to support updated demographic data (UN WPP 2022/2024) and recent `socialmixr` (>= 0.5.0) contact matrix interfaces.
* Added automated numerical verification assertions in `inst/analysis/scripts/run_numbers.R` to ensure simulation results match published findings.
* Added automated CI verification recipe (`just test-analysis`) ensuring the demonstration analysis runs cleanly from the installed package.

### Build and CI Infrastructure
* Modernized developer workflows using `justfile`, automated code formatting via `air`, and linting via `lintr`.
* Integrated `roxyglobals` to automate global variable binding declarations in `R/globals.R`.
* Updated GitHub Actions CI workflows for multi-platform checks (Linux, macOS, Windows) and automated documentation deployment.
