# Regression test: reproduce the manuscript's own worked example (SPD vote,
# Germany 1957, from Hooghe & Marks 2025: 18, as re-derived in
# manuscript.qmd sections "The Alford Index" and "Party Cleavage Index")
# to numerically verify icv(), contribution(), and pci().
#
# Run via: testthat::test_file("tests/testthat/test-indices.R")
# (after sourcing R/functions_derive.R, e.g. via tests/testthat.R)

test_that("icv() reproduces the manuscript's 1957 SPD example", {
  p_spd_given_worker <- 0.343
  p_worker <- 0.474
  p_spd <- 0.217

  p_spd_given_nonworker <- complement_conditional(p_spd, p_spd_given_worker, p_worker)
  expect_equal(p_spd_given_nonworker, 0.1035, tolerance = 1e-3)

  expect_equal(
    icv(p_spd_given_worker, p_spd_given_nonworker),
    0.2395,
    tolerance = 1e-3
  )
})

test_that("contribution() and pci() reproduce the manuscript's 1957 SPD example", {
  p_spd_given_worker <- 0.343
  p_worker <- 0.474
  p_spd <- 0.217

  # manuscript.qmd, eq-pci: Pr(Worker | SPD) = 0.749
  expect_equal(
    contribution(p_spd_given_worker, p_worker, p_spd),
    0.749,
    tolerance = 1e-3
  )

  # manuscript.qmd: PCI = 0.749 - 0.474 = 0.275
  expect_equal(
    pci(p_spd_given_worker, p_worker, p_spd),
    0.275,
    tolerance = 1e-3
  )
})

test_that("contribution() and icv() are consistent with each other (Bayes' rule symmetry)", {
  # Pr(A|B) * Pr(B) == Pr(B|A) * Pr(A) for arbitrary valid inputs
  p_a_given_b <- 0.4
  p_b <- 0.3
  p_a <- 0.35

  p_b_given_a <- contribution(p_a_given_b, p_b, p_a)
  expect_equal(p_b_given_a * p_a, p_a_given_b * p_b, tolerance = 1e-8)
})
