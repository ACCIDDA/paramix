# paramix

Tools for calculating aggregate parameters and for disaggregating
outcomes.

## Overview

For more complex infectious disease [compartmental
models](https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology),
you may need to represent populations groups which discretize or group
some continuous feature. For example, your model might use broad age
groups, but you might have higher resolution data on critical processes
by age. And once you’ve run your model, you might want outcomes
associated with those processes at finer resolution for some follow on
analyses.

The `paramix` package provides convenient functions to create both the
correct aggregate parameters and to disaggregate outcomes.

## Installation

``` r

install.packages("paramix")
```

Or install the development version from GitHub:

``` r

remotes::install_github("accidda/paramix")
```

## Usage

Briefly, there are three steps:

- create a translation object (`alembic`) based on the parameter
  function (e.g. the infection fatality ratio as a function of age), the
  density distribution of the pertinent feature (e.g. the population age
  pyramid), the model partitions of the feature (e.g. age groups), and
  the post-processing partitions of the feature (e.g. age in years).
- create model parameters (`blend`) from the alembic
- apply the alembic to model results (`distill`) to impute higher
  resolution outcomes

## Reproducing the Paper Analysis

We describe the methodology and applications of `paramix` in:

> Goodfellow L, Pearson CAB, Procter SR (2025). “paramix: An R package
> for parameter discretisation in compartmental models, with application
> to calculating years of life lost.” *PLOS Computational Biology*,
> 21(9): e1013420. <https://doi.org/10.1371/journal.pcbi.1013420>

To reproduce the complete simulation study, figures, and numerical
results from the paper using the bundled GNU Make and `renv` pipeline,
see the vignette:

``` r

vignette("reproducing-paper-analysis", package = "paramix")
```

or read the [online reproduction
vignette](https://accidda.github.io/paramix/articles/reproducing-paper-analysis.html).
