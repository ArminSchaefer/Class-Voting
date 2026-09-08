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

# ---------------------------------------------------------------------------
# Germany, simple (non-hierarchical) model -- promoted from
# scripts/analyze_ess_ger.qmd once the specification was finalized there.
#
# Unlike clean_ess() above, this does NOT start from raw ESS microdata: its
# input is data/processed/essger.rds, which is already merged with the
# class scheme and party-vote coding by scripts/process_ess_ger*.qmd
# (upstream of this targets pipeline, not yet itself a target -- see the
# note in _targets.R). This function does only the final, analysis-specific
# recoding: constructing rightvote/worker and restricting to the finalized
# analysis sample.
# ---------------------------------------------------------------------------

#' Prepare the Germany, 2017+2021, voters-only analysis sample for the
#' simple radical-right-vote model.
#'
#' Data decisions (see DATA_PROVENANCE.md for the full record):
#'   - Restricted to the 2017 and 2021 Bundestag elections. The notebook's
#'     original exploratory cut was btw >= 2013 (to exclude the pre-AfD
#'     elections, where radical-right vote was ~0%); after checking the
#'     fitted models, 2013 itself was also dropped.
#'   - Voters only: rows with pvote == NA (non-voters) are dropped, rather
#'     than the notebook's original population-based coding via
#'     pvote_non_voter (which folded non-voters into the "not radical
#'     right" category).
#'
#' @param essger Cleaned German ESS data as in data/processed/essger.rds.
#' @return A tibble with one row per voter with complete data on
#'   rightvote/worker/age_grp/gender/immigrant/union, ready for
#'   fit_model_ger_simple().
clean_ess_ger_simple <- function(essger) {
  essger |>
    dplyr::filter(btw %in% c(2017, 2021)) |>
    dplyr::filter(!is.na(pvote)) |>
    dplyr::mutate(
      rightvote = as.numeric(pvote == "radical right"),
      worker = dplyr::case_when(
        is.na(class5) ~ NA_real_,
        class5 %in% c(4, 5) ~ 1, # Skilled workers, Low-skilled workers
        TRUE ~ 0                  # Higher/Lower-grade service class, Small business
      ),
      age_grp = factor(age_grp, levels = c("18-29", "30-65", "66+")),
      gender  = factor(gender,  levels = c("female", "male"))
    ) |>
    tidyr::drop_na(rightvote, worker, age_grp, gender, immigrant, union)
}
