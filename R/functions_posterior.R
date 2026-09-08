# ---------------------------------------------------------------------------
# Fully Bayesian ICV / ACI / PCI
#
# This is the operationalization of the manuscript's unwritten final
# section, "From Bayes' rule to Bayesian estimation": apply the closed-form
# formulas in functions_derive.R (icv(), contribution(), pci()) to EVERY
# posterior draw of Pr(vote_rr | worker, country, round), rather than to a
# single point estimate, so the output is a full posterior distribution of
# each index -- see ANALYSIS_PLAN.md, section 6.
# ---------------------------------------------------------------------------

#' Compute posterior draws of ICV / contribution / PCI from a fitted model.
#'
#' @param fit A fitted brmsfit (expected: the varying-slope model, M2).
#' @param ess_clean Cleaned ESS data (for Pr(worker) by country/round, and
#'   as the newdata grid for posterior_epred()/add_epred_draws()).
#' @return A tibble of posterior draws, long by (.draw, country, round),
#'   with columns for p_rr_given_worker, p_rr_given_nonworker, icv,
#'   contribution, and pci.
compute_posterior_indices <- function(fit, ess_clean) {
  # TODO, sketch:
  #   grid <- tidyr::expand_grid(country = ..., round = ..., worker = c(0, 1))
  #   draws <- tidybayes::add_epred_draws(grid, fit) # Pr(vote_rr | worker, c, r) per draw
  #   draws_wide <- draws %>%
  #     tidyr::pivot_wider(names_from = worker, values_from = .epred,
  #                         names_prefix = "p_rr_given_worker") %>%
  #     dplyr::mutate(
  #       icv = icv(p_rr_given_worker1, p_rr_given_worker0),
  #       # p_group and p_party per draw: either fixed from ess_clean marginals
  #       # or themselves modeled with uncertainty -- decide and document
  #       # (ANALYSIS_PLAN.md sec. 6) before implementing contribution()/pci().
  #     )
  stop("compute_posterior_indices(): not yet implemented -- needs a fitted model.")
}
