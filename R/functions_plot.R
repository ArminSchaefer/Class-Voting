# ---------------------------------------------------------------------------
# Figures and tables for the manuscript
# ---------------------------------------------------------------------------

#' Plot the posterior distribution of a cleavage index by country.
#'
#' @param posterior_indices Output of compute_posterior_indices().
#' @param index One of "ICV", "ACI" (contribution), "PCI".
#' @return Path to the saved figure file (for targets `format = "file"`).
plot_posterior_index <- function(posterior_indices, index = c("ICV", "ACI", "PCI")) {
  index <- match.arg(index)
  # ggplot2 + ggdist::stat_halfeye() over posterior draws, faceted by
  # country and/or round; ggsave() to here::here("figs", ...) and return
  # that path.
  stop("plot_posterior_index(): not yet implemented -- needs posterior_indices.")
}

#' Export a model summary table (fixed + group-level effects) for the
#' manuscript.
#'
#' @param fit A fitted brmsfit.
#' @return Path to the saved table file (for targets `format = "file"`).
export_model_table <- function(fit) {
  # modelsummary::modelsummary(fit, statistic = "conf.int", ...) or a
  # gt-based table; save to here::here("tables", ...) and return that path.
  stop("export_model_table(): not yet implemented -- needs a fitted model.")
}
