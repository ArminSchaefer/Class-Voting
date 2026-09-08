# ---------------------------------------------------------------------------
# Cleaning and harmonization
#
# Every recoding rule implemented here (worker/non-worker, RR-party vote,
# which weight to use) must be documented in DATA_PROVENANCE.md -- code
# alone does not make a coding decision auditable to a reader who doesn't
# read R.
# ---------------------------------------------------------------------------

#' Harmonize raw ESS data into an analysis-ready tibble.
#'
#' Expected output columns (adjust as decisions are finalized):
#'   - country, round (factors)
#'   - worker (0/1)              -- from occupational class, see DATA_PROVENANCE.md
#'   - vote_rr (0/1)              -- radical-right party vote, per-country coding
#'   - weight (numeric)           -- chosen ESS weight, see ANALYSIS_PLAN.md sec. 4
#'
#' @param ess_raw Output of import_ess().
#' @return A cleaned tibble ready for compute_classic_indices() and the
#'   brms models in functions_model.R.
clean_ess <- function(ess_raw) {
  # TODO: recode occupation -> worker/non-worker (e.g. via ISCO-08 -> ESeC/EGP)
  # TODO: recode per-country vote variable -> vote_rr using an explicit,
  #       documented party classification (PopuList / ParlGov / CHES)
  # TODO: select and rename the appropriate weight variable
  stop("clean_ess(): not yet implemented -- see DATA_PROVENANCE.md.")
}
