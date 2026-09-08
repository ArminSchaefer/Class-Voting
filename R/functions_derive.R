# ---------------------------------------------------------------------------
# Closed-form cleavage indices (Bayes' rule)
#
# Alford's (1962) Index of Class Voting, Axelrod's (1972) Contribution
# Index, and Hooghe & Marks' (2025) Party Cleavage Index are all
# re-expressions of Bayes' rule applied to a 2x2 table of
# {group membership} x {party choice} -- see manuscript.qmd, section
# "Measuring Loyalty and Contribution". These functions take *probabilities*
# (proportions) as arguments, not raw data, so they are pure and easily
# tested in isolation (see tests/testthat/test-indices.R, which reproduces
# the manuscript's own 1957 SPD worked example).
#
# compute_classic_indices() is the one function here still to be written --
# it applies the pure functions below, grouped by country/round/party, to
# empirical proportions computed from the cleaned ESS data.
# ---------------------------------------------------------------------------

#' Alford's (1962) Index of Class Voting
#'
#' ICV = Pr(party | group) - Pr(party | ~group)
#'
#' @param p_party_given_group    Pr(vote party | group), e.g. workers
#' @param p_party_given_nongroup Pr(vote party | ~group), e.g. non-workers
#' @return numeric (scalar or vector)
icv <- function(p_party_given_group, p_party_given_nongroup) {
  p_party_given_group - p_party_given_nongroup
}

#' Contribution of a group to a party's vote (Axelrod 1972; Hooghe & Marks 2025)
#'
#' Pr(group | party) = Pr(party | group) * Pr(group) / Pr(party)
#'
#' @param p_party_given_group Pr(vote party | group)
#' @param p_group             Pr(group) -- the group's size in the population
#' @param p_party             Pr(vote party) -- the party's overall vote share
#' @return numeric (scalar or vector)
contribution <- function(p_party_given_group, p_group, p_party) {
  (p_party_given_group * p_group) / p_party
}

#' Hooghe & Marks' (2025) Party Cleavage Index
#'
#' PCI = Pr(group | party) - Pr(group)
#'
#' @inheritParams contribution
#' @return numeric (scalar or vector)
pci <- function(p_party_given_group, p_group, p_party) {
  contribution(p_party_given_group, p_group, p_party) - p_group
}

#' Recover Pr(party | ~group) from the marginal Pr(party) via the law of
#' total probability, when only Pr(party | group), Pr(group), and Pr(party)
#' are known (mirrors the "solve for x" step in manuscript.qmd's SPD
#' example).
#'
#' Pr(party) = Pr(party | group) * Pr(group) + Pr(party | ~group) * Pr(~group)
#'
#' @return numeric (scalar or vector)
complement_conditional <- function(p_party, p_party_given_group, p_group) {
  (p_party - p_party_given_group * p_group) / (1 - p_group)
}

#' Apply icv() / contribution() / pci() to empirical proportions from the
#' cleaned ESS data, by country, round, and party.
#'
#' @param ess_clean Output of clean_ess().
#' @return A tibble with one row per country x round x party, containing
#'   the closed-form ICV, contribution, and PCI (point estimates only --
#'   see compute_posterior_indices() in functions_posterior.R for the fully
#'   Bayesian, uncertainty-aware version).
compute_classic_indices <- function(ess_clean) {
  # TODO: group_by(country, round) %>% summarise(p_worker = ..., p_rr = ...,
  #   p_rr_given_worker = ..., p_rr_given_nonworker = ...) and apply the
  #   pure functions above.
  stop("compute_classic_indices(): not yet implemented -- data not available yet.")
}
