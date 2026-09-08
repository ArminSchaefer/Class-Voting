# _targets.R
#
# Pipeline definition for "Voting for a Party and Contributing to a Party's
# Vote". This is the single source of truth for how raw ESS data becomes
# cleaned data, fitted models, posterior-based indices, and manuscript
# figures/tables. Run with `targets::tar_make()`; inspect with
# `targets::tar_visnetwork()`.
#
# STATUS: scaffold only. Every target below calls a function in R/ that is
# currently an unimplemented stub (see R/functions_*.R) — fill these in as
# data and model specifications are finalized (ANALYSIS_PLAN.md).

library(targets)

tar_source("R")

tar_option_set(
  packages = c(
    "tidyverse", "here", "brms", "tidybayes", "ggdist",
    "posterior", "bayesplot", "loo", "survey", "srvyr",
    "modelsummary", "marginaleffects", "gt"
  )
)

list(
  # --- Germany, simple (non-hierarchical) model ---------------------------
  # Promoted from scripts/analyze_ess_ger.qmd. NOTE: essger.rds is not raw
  # ESS microdata -- it is already merged with the class scheme and
  # party-vote coding by scripts/process_ess_ger*.qmd, which are not yet
  # targets themselves (a natural next step, once that upstream processing
  # is stable enough to freeze into functions too).
  tar_target(
    essger_file,
    here::here("data", "processed", "essger.rds"),
    format = "file"
  ),
  tar_target(essger_raw, readRDS(essger_file)),
  tar_target(ess_ger_model_data, clean_ess_ger_simple(essger_raw)),
  tar_target(model_ger_simple, fit_model_ger_simple(ess_ger_model_data)),

  # --- Data import & cleaning (cross-national, future) --------------------
  tar_target(raw_data_file, here::here("data", "raw", "ess_rounds.rds"), format = "file"),
  tar_target(ess_raw, import_ess(raw_data_file)),
  tar_target(ess_clean, clean_ess(ess_raw)),

  # --- Closed-form cleavage indices (Bayes' rule, point estimates) -------
  tar_target(indices_closed_form, compute_classic_indices(ess_clean)),

  # --- Bayesian models, increasing complexity (see ANALYSIS_PLAN.md) -----
  tar_target(model_pooled, fit_model_pooled(ess_clean)),
  tar_target(model_varying_intercept, fit_model_varying_intercept(ess_clean)),
  tar_target(model_varying_slope, fit_model_varying_slope(ess_clean)),

  # --- Model comparison and diagnostics -----------------------------------
  tar_target(
    model_comparison,
    compare_models(model_pooled, model_varying_intercept, model_varying_slope)
  ),
  tar_target(diagnostics, run_diagnostics(model_varying_slope)),

  # --- Fully Bayesian ICV / ACI / PCI (posterior draws) -------------------
  tar_target(posterior_indices, compute_posterior_indices(model_varying_slope, ess_clean)),

  # --- Figures and tables for the manuscript ------------------------------
  tar_target(
    fig_posterior_icv,
    plot_posterior_index(posterior_indices, index = "ICV"),
    format = "file"
  ),
  tar_target(
    tbl_model_summary,
    export_model_table(model_varying_slope),
    format = "file"
  )
)
