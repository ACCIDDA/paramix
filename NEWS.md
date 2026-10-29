# paramix 0.0.3

### Documentation and Vignettes

* Added a dedicated vignette `reproducing-paper-analysis` describing how to run the simulation study from Goodfellow et al. (2025) <doi:10.1371/journal.pcbi.1013420>, including reference tables comparing calculated outputs with published findings.
* Updated package citation metadata in `DESCRIPTION` and `inst/CITATION` for the published *PLOS Computational Biology* paper.
* Extended and clarified mathematical formulations in roxygen documentation and vignettes.
* Added a package hex logo in `man/figures/logo.png` and configured pkgdown favicons with light/dark theme support.
* Removed generated documentation (`man/*.Rd`) and intermediate vignette outputs from version control, managing them dynamically through `just docs`.

### Error Handling and Validation

* Centralized user-facing error and warning signaling into reusable, named format templates in `R/messages.R`.
* Added comprehensive unit test coverage for all input validation and signaling paths in `tests/testthat/test-messages.R`.
* Integrated `roxyglobals` to automate global variable declarations in `R/globals.R`.

### Demonstration Analysis and Reproducibility

* Modernized the bundled analysis scripts in `inst/analysis/` to support updated demographic data (UN WPP 2022/2024) and modern `socialmixr` (>= 0.5.0) contact matrix interfaces.
* Added automated numerical assertions in `inst/analysis/scripts/run_numbers.R` comparing calculated 65+ IFR increases, averted deaths, and averted YLLs directly against published benchmarks.
* Added `just test-analysis` workflow and a dedicated CI action to verify that the reproduction pipeline executes successfully.

### Build and Developer Workflows

* Standardized developer workflows via `justfile` recipes (`format`, `lint`, `docs`, `install`, `test`, `coverage`, `site`, `check`).
* Enforced code formatting via `air` and static linting via `lintr`.
* Added automated package spell checking via `tests/spelling.R` and `inst/WORDLIST`.
* Modernized GitHub Actions CI workflows for multi-platform checks (Linux, macOS, Windows), automated linting, test coverage reporting, and automated pkgdown deployment.

# paramix 0.0.2

* Extended documentation to clarify mathematical formulation of the mixing table.
