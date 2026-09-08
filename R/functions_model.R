# ---------------------------------------------------------------------------
# Bayesian multilevel models (brms)
#
# Working outcome: vote_rr (1 = voted for a radical-right party, 0 =
# reference category -- decide and document what the reference category is,
# e.g. all other parties, or all other parties + non-voters, in
# DATA_PROVENANCE.md).
# Working predictor: worker (0/1).
# Grouping structure: individuals nested in country-rounds nested in
# countries (see ANALYSIS_PLAN.md, section 2, for the full generative model
# and section 3 for priors). Models are built in increasing complexity so
# they can be compared via LOO (compare_models()).
#
# Every brm() call below is commented out: these are specifications to
# review and adapt, not verified-executable code, since there is no data
# yet to fit against.
# ---------------------------------------------------------------------------

#' M0: complete pooling -- baseline only, no hierarchical structure.
fit_model_pooled <- function(ess_clean) {
  # brms::brm(
  #   vote_rr ~ 1 + worker,
  #   data   = ess_clean,
  #   family = bernoulli(),
  #   prior  = c(
  #     brms::prior(normal(0, 1.5), class = "Intercept"),
  #     brms::prior(normal(0, 1),   class = "b")
  #   ),
  #   chains = 4, cores = 4, seed = 2026
  # )
  stop("fit_model_pooled(): not yet implemented -- data not available yet.")
}

#' M1: varying intercepts by country and round.
fit_model_varying_intercept <- function(ess_clean) {
  # brms::brm(
  #   vote_rr ~ 1 + worker + (1 | country) + (1 | round),
  #   data   = ess_clean,
  #   family = bernoulli(),
  #   prior  = c(
  #     brms::prior(normal(0, 1.5), class = "Intercept"),
  #     brms::prior(normal(0, 1),   class = "b"),
  #     brms::prior(exponential(1), class = "sd")
  #   ),
  #   chains = 4, cores = 4, seed = 2026
  # )
  stop("fit_model_varying_intercept(): not yet implemented.")
}

#' M2: varying slope for `worker` by country -- the hierarchical, partially
#' pooled version of the manuscript's Alford/ICV quantity.
fit_model_varying_slope <- function(ess_clean) {
  # brms::brm(
  #   vote_rr ~ 1 + worker + (1 + worker | country) + (1 | round),
  #   data   = ess_clean,
  #   family = bernoulli(),
  #   prior  = c(
  #     brms::prior(normal(0, 1.5), class = "Intercept"),
  #     brms::prior(normal(0, 1),   class = "b"),
  #     brms::prior(exponential(1), class = "sd"),
  #     brms::prior(lkj(2),         class = "cor")
  #   ),
  #   chains = 4, cores = 4, seed = 2026
  # )
  stop("fit_model_varying_slope(): not yet implemented.")
}

#' Compare fitted models via LOO-CV, reporting ELPD differences with SEs.
#'
#' @param ... Two or more fitted brmsfit objects.
compare_models <- function(...) {
  # models <- list(...)
  # loos   <- lapply(models, loo::loo)
  # loo::loo_compare(loos)
  stop("compare_models(): not yet implemented.")
}
