# Contributing to paramix

Thank you for your interest in contributing to `paramix`! This guide explains how to contribute to the package and how to keep the project documentation clear, consistent, and approachable.

---

## Architecture & Scope

`paramix` (*Aggregate and Disaggregate Continuous Parameters for Compartmental Models*) is an R package within the ACCIDDA organization providing a convenient framework for aggregating continuously varying parameters for compartmental models and subsequent upscaling (distillation) of model outcomes to high resolution.

* **Package Scope**:
  * **Continuous Parameter Translation**: Discretizing continuous or high-resolution parameters (`f_param`, e.g., age-varying infection fatality ratio or case fatality ratio) across population density distributions (`f_pop`, e.g., demographic pyramids) onto lower-resolution compartmental model partitions.
  * **Alembic Engine (`alembic`)**: Constructing the core mixing table as the union of model and output partitions, calculating exact integration weights ($\int_{c_i}^{c_{i+1}} f(x)\rho(x)\,\mathrm{d}x$) and relative populations ($\int_{c_i}^{c_{i+1}} \rho(x)\,\mathrm{d}x$).
  * **Parameter Blending (`blend`)**: Extracting population-weighted aggregate parameters for model partitions ($\sum \text{weight} / \sum \text{relpop}$).
  * **Outcome Distillation (`distill`)**: Upscaling coarse model outcomes (e.g., compartment deaths or infections) into high-resolution output partitions using Bayesian proportional allocation ($\text{weight}_i / \sum \text{weight}_j$).
  * **Comparison & Summary Utilities (`parameter_summary`, `distill_summary`)**: Diagnostic summaries and tabular comparisons across continuous, midpoint, naive, and integrated aggregation schemes.

---

## Coding Standards & Tooling

We adhere to modern R package conventions and use automated tooling for code formatting and quality checks:

### 1. Code Formatting with `air`
* All R code must be formatted using [`air`](https://github.com/posit-dev/air).
* Format your code locally before committing:
  ```sh
  just format
  ```

### 2. Static Analysis with `lintr`
* We use `lintr` to ensure style consistency (line length $\le 100$, snake_case naming, implicit return style).
* Check your code locally:
  ```sh
  just lint
  ```

### 3. Documentation with `roxygen2`
* All public and internal functions must be thoroughly documented using `roxygen2` with Markdown support enabled (`Roxygen: list(markdown = TRUE, ...)`).
* Always use explicit `@title` and `@description` tags in roxygen documentation blocks.
* Unexported internal functions should be marked with `@keywords internal` and `@noRd` to keep code documented in source without generating unused `.Rd` files.
* `man/*.Rd` and `NAMESPACE` are generated from roxygen comments:
  ```sh
  just docs
  ```

### 4. Voice and Clarity in Documentation and Vignettes
* Write user-facing prose in active voice with an explicit actor.
* Start with the person, package, or function doing the work: "We designed `paramix` to aggregate continuous parameters" or "This workflow allocates compartment outcomes to individual years of age."
* Where possible, avoid pronouns in explanatory prose. Use a noun instead: for example, "the function calculates" instead of "it calculates". However, "we" for authorial voice and "you" for the reader are preferred.
* Prefer concrete, direct verbs over passive phrasing or abstract placeholders. Avoid heavy nominalizations, redundant `to be` constructions, and jargon that readers need to decode before they reach the point.
* Keep the narrative conversational but formal. Explain the problem, then show how the code solves it in plain English.
* Use consistent terminology across documentation and vignettes so readers can follow the same concept from the intro to the examples.

---

## Unit Testing & Test-Driven Development

We use `testthat` (edition 3) for unit and integration testing.

### 1. Running Tests
* Run full test suite:
  ```sh
  just test
  ```
* Run test suite stopping on first failure:
  ```sh
  just test-fast
  ```
* Check test coverage:
  ```sh
  just coverage
  ```

### 2. Error Messages, Signaling Standards, and Unit Testing

All user-facing validation errors and warnings should follow these standards:

#### Centralized Named Template Constants
* Define error and warning message format strings as constants at the top of each R file prefixed with `ERR_` or `MSG_`:
* Use named `{var}` placeholders rather than unnamed format tokens:
  ```r
  ERR_INPUT_FILE_MISSING <- "input file '{filename}' was not found in directory '{dir}'"
  ```

#### Typography: Backticks vs. Single Quotes
* **Backticks (`` `code` ``)**: Use for formal R code symbols, argument names, function names, expressions, and classes (e.g. `` `model_partition` must be a numeric vector ``).
* **Single Quotes (`'value'`)**: Use for user-supplied string values, file paths, column names, or discrete inputs (e.g. `` column '{col}' not found ``).

#### Markdown List Formatting Standards
* Precede list blocks with an empty blank line after introductory text.
* Use consistent bullet markers (`-`) for unordered lists and (`1.`, `2.`) for top-level ordered sequences.
* Indent sub-lists by 2 or 4 spaces and wrap continuations with matching margins.

---


## Pull Request and CI Workflows

Every pull request triggers automated GitHub Actions workflows that delegate directly to `justfile` recipes:

1. **`R-CMD-check`**: Runs `R CMD check --as-cran` across Ubuntu, macOS, and Windows on R release, oldrel, and devel, using shared build artifacts.
2. **`lint`**: Runs `just lint` (verifying `air format . --check` and `lintr::lint_package()`).
3. **`test-coverage`**: Computes code coverage with `covr` and uploads results to Codecov.
4. **`pkgdown`**: Builds the documentation site and validates vignettes. Deployed to GitHub Pages upon push to `main` and published releases.

All checks must pass before merging.
