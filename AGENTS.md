# AGENTS.md — Developer and AI Agent Guidelines for paramix

This guide explains the architecture, coding conventions, testing
standards, and development workflow for contributors and AI coding
agents working on `paramix`.

------------------------------------------------------------------------

## 1. Role, Scope & Package Architecture

`paramix` (*Aggregate and Disaggregate Continuous Parameters for
Compartmental Models*) is an R package within the ACCIDDA organization
providing a convenient framework for aggregating continuously varying
parameters for compartmental models and subsequent upscaling
(distillation) of model outcomes to high resolution.

- **Package Scope**:
  - **Continuous Parameter Translation**: Discretizing continuous or
    high-resolution parameters (`f_param`, e.g., age-varying infection
    fatality ratio or case fatality ratio) across population density
    distributions (`f_pop`, e.g., demographic pyramids) onto
    lower-resolution compartmental model partitions.
  - **Alembic Engine (`alembic`)**: Constructing the core mixing table
    as the union of model and output partitions, calculating exact
    integration weights
    ($`\int_{c_i}^{c_{i+1}} f(x)\rho(x)\,\mathrm{d}x`$) and relative
    populations ($`\int_{c_i}^{c_{i+1}} \rho(x)\,\mathrm{d}x`$).
  - **Parameter Blending (`blend`)**: Extracting population-weighted
    aggregate parameters for model partitions
    ($`\sum \text{weight} / \sum \text{relpop}`$).
  - **Outcome Distillation (`distill`)**: Upscaling coarse model
    outcomes (e.g., compartment deaths or infections) into
    high-resolution output partitions using Bayesian proportional
    allocation ($`\text{weight}_i / \sum \text{weight}_j`$).
  - **Comparison & Summary Utilities (`parameter_summary`,
    `distill_summary`)**: Diagnostic summaries and tabular comparisons
    across continuous, midpoint, naive, and integrated aggregation
    schemes.

------------------------------------------------------------------------

## 2. Core Tenets & Development Workflows

### The `justfile` as Single Source of Truth

- All builds, linting, formatting, tests, documentation generation, and
  site previews must be performed via `justfile` recipes.
- CI workflows (`.github/workflows/*.yaml`) invoke `just <recipe>`.

Common recipes:

``` sh
just format        # Format R code using air
just lint          # Check formatting and linting (air + lintr)
just docs          # Regenerate man/*.Rd, NAMESPACE, R/globals.R
just install       # Install development version of package
just test          # Run testthat test suite
just test-fast     # Run test suite stopping on first failure
just coverage      # Check test coverage via covr
just spell         # Check documentation spelling
just site          # Fast build of pkgdown documentation site
just site-full     # Full build of pkgdown documentation site with install
just check         # Build and check package tarball
just check-cran    # Check package with --as-cran
```

------------------------------------------------------------------------

## 3. R Coding & Quality Standards

### Code Formatting (`air`) & Linting (`lintr`)

- All R files must adhere to `air` formatting (`indent-width = 2`,
  `line-width = 80`).
- `lintr` enforces line length $`\le 100`$, snake_case naming (allowing
  `paramix`, `ERR_`, `MSG_`), and implicit returns.
- Always run `just format && just lint` before finishing any task.

### Error Messages & Signaling Standards

- Define centralized error and warning format strings at the top of R
  files:

  ``` r

  ERR_INPUT_FILE_MISSING <- "input file '{filename}' was not found in directory '{dir}'"
  ```

- Use named `{var}` placeholders rather than unnamed format tokens.

- Format code entities (function names, formal parameters, R
  expressions) with **backticks (`` `code` ``)**.

- Format user-supplied values, paths, and column names with **single
  quotes (`'value'`)**.

### Documentation (`roxygen2`)

- Use Markdown-formatted roxygen comments.
- Always use explicit `@title` and `@description` tags in roxygen
  blocks.
- Unexported internal functions should be marked with
  `@keywords internal` and `@noRd` to keep code documented in source
  without generating unused `.Rd` files.
- Document `@param` concisely with type and default where applicable.
- Document `@return` explicitly describing return type and structure.
- For exported functions, include runnable and fast `@examples` (or
  `@examplesIf require(...)`).

### Documentation and Vignette Voice

- Write user-facing prose in active voice with a clear actor.
- Prefer direct phrasing such as “We designed `paramix` to aggregate
  continuous parameters” or “This workflow allocates compartment
  outcomes to individual years of age” rather than passive phrasing such
  as “`paramix` is designed to be used for…” or “parameters are often
  aggregated by…”.
- Where possible, avoid pronouns in explanatory prose. Use a noun
  instead: for example, “the function calculates” instead of “it
  calculates”. However, “we” for authorial voice and “you” for the
  reader are preferred.
- Keep the subject explicit and the action concrete. Explain the
  problem, what the package does, and why it matters in plain English
  before you expand into implementation details.
- Use a conversational but formal tone. Favor strong verbs and concrete
  nouns over heavy jargon, abstract nominalizations, and repeated
  `to be` constructions.
- Define domain terms once and use them consistently across roxygen
  comments, vignettes, and package docs.

### Unit Testing (`testthat`)

- All user-facing functions must have comprehensive test coverage in
  `tests/testthat/`.
- Test both expected success paths and error conditions.
- Assert on error messages using exact regex or template pattern
  matching.
- Ensure tests run cleanly across Linux, macOS, and Windows.

------------------------------------------------------------------------

## 4. Git & Commit Guidelines

- Maintain a clean git history.
- Keep commit messages descriptive and focused.
- Do not commit generated build artifacts (`*.tar.gz`, `*.Rcheck/`,
  `docs/`, `man/*.Rd`, `R/globals.R`).
