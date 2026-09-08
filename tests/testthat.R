library(testthat)

# Source the pure functions directly rather than requiring a package
# structure -- this project is a research pipeline, not an R package.
source(here::here("R", "functions_derive.R"))

test_dir(here::here("tests", "testthat"))
