# ---------------------------------------------------------------------------
# Convergence diagnostics and posterior predictive checks
# ---------------------------------------------------------------------------

#' Run standard convergence and fit diagnostics on a fitted brmsfit.
#'
#' Never accept a model as fit for use based on this function's *code*
#' looking right -- always inspect the actual Rhat/ESS values and pp_check
#' plot yourself (ANALYSIS_PLAN.md, "Do not delegate").
#'
#' @param fit A fitted brmsfit.
#' @return A list with convergence summary, ESS/Rhat table, and pp_check plot.
run_diagnostics <- function(fit) {
  # list(
  #   summary   = summary(fit),                              # Rhat, Bulk_ESS, Tail_ESS
  #   draws_sum = posterior::summarise_draws(fit),            # full per-parameter diagnostics
  #   pp_check  = brms::pp_check(fit, ndraws = 100),          # density overlay
  #   pp_check_by_group = brms::pp_check(
  #     fit, type = "stat_grouped", group = "country", stat = "mean"
  #   )
  # )
  stop("run_diagnostics(): not yet implemented -- needs a fitted model.")
}
