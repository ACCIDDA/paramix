
# QUICK START

You will need `gnumake` (or other `make` with compatible syntax support), `R`, and the `renv` `R` package installed.

To run the analysis, go to a command prompt and enter:

```bash
path/to/this/directory$ make -j4
```

The `-j4` option enables running the parts of the analysis in parallel. This analysis has a two-by-two scenario setup, so 4 is the maximum useful amount of parallelization. If your system has fewer cores (or highly constrained memory), feel free to use a smaller number or remove the option entirely for serial run only.

You will be prompted by `renv` to agree to setting up the `renv` environment.

# NOTE ON PACKAGE DEPENDENCIES & REPRODUCIBILITY

This analysis pipeline uses modernized R package dependencies (including `socialmixr >= 0.5.0` API conventions) rather than the historical frozen library snapshot used at manuscript submission. The demographic data snapshot is **identical** to the published paper: population pyramids and life tables are drawn from the UN World Population Prospects 2022 (`wpp2022`, 2021 estimates). While dependency versions and function argument conventions have evolved, we confirmed that the analysis scripts fully recover the exact numerical quantities and figures reported in Goodfellow et al. (2025). The final `values` build target automatically executes `scripts/run_numbers.R` to print these verified reference figures.

# DETAILS

This analysis comprises stages: building up inputs, transforming them to outputs, and then visualizing those outputs. The explicit commands for that process are specified in the `GNUmakefile`. The scripts behind those commands are in the `scripts` folder.

The stage results are stored roughly as follows:

 - inputs downloaded into the `input` directory
 - outputs generated, then written to the `output` directory
 - figures generated, then written to the `figure` directory
