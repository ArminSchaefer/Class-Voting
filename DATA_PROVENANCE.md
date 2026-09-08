# Data Provenance

Fill this in as soon as the data source is finalized — it is the record that
makes the project's empirical claims auditable and is required before any
data-derived result should be trusted or published.

## Source

- **Dataset**: European Social Survey (ESS) — *round(s): TBD, e.g. 1–11*
- **Edition/version**: TBD (ESS reissues rounds with corrections; record the
  exact edition number, e.g. "ESS11 – integrated file, edition 1.0")
- **Access method**: TBD — e.g. `essurvey::import_rounds()` (R package
  authenticating against the ESS API with a personal access token), or manual
  export from the ESS Data Portal (https://ess.sikt.no/)
- **Access date**: TBD
- **Countries included**: TBD
- **License / terms of use**: ESS microdata are free for academic/non-commercial
  use but **may not be redistributed**. Raw files therefore live only in
  `data/raw/` (git-ignored) on this machine — never commit them, and note this
  restriction if the repository is later made public.

## Key variables and coding decisions

Document every recoding decision here, not just in code comments — this is
what lets someone (including future-you) audit *why* a case was coded as
"worker" or "radical right" without re-reading the pipeline.

- **Class scheme**: `data/processed/class_scheme.rds` / `ess_class_scheme.rds`
  provide `class16`/`class8`/`class5` (increasingly aggregated occupational
  class categories, in the style of Oesch's class schemes) already merged
  into `data/processed/essger.rds`. **TBD**: document here the exact
  ISCO-08 -> class16 mapping rule used to build `class_scheme.rds` (which
  script/source produced it) — not yet traced in this file.
- **Worker / non-worker** (`R/functions_clean.R::clean_ess_ger_simple()`, same
  definition as originally tried in `scripts/analyze_ess_ger.qmd`): `worker =
  1` if `class5 %in% c(4, 5)` ("Skilled workers", "Low-skilled workers"),
  `0` if `class5 %in% c(1, 2, 3)` ("Higher-grade service class",
  "Lower-grade service class", "Small business"), else `NA`. This is the
  classic manual-worker definition (Alford's "manual workers"); ~16% of
  `essger.rds` (4,518 / 28,547) have `class5 = NA` (occupational class
  unavailable, typically respondents outside the labour force) and are
  dropped by listwise deletion.
- **Radical-right party vote, Germany, finalized model**
  (`R/functions_clean.R::clean_ess_ger_simple()`, used by
  `fit_model_ger_simple()` / target `model_ger_simple`): `rightvote = 1` if
  `pvote == "radical right"`, computed among **voters only** (`pvote == NA`
  rows -- non-voters -- are dropped, not folded into "not radical right").
  Restricted to the **2017 and 2021** Bundestag elections. **TBD**: document
  here which per-country party classification produced `pvote` (own coding?
  PopuList? ParlGov?) and its version/date — not yet traced in this file.
  For Germany this resolves to the AfD. Superseded exploratory version (kept
  in `scripts/analyze_ess_ger.qmd` as a record, not run by the pipeline):
  population-based coding via `pvote_non_voter` (folding non-voters into
  "not radical right") over `btw >= 2013`; pre-2013 "radical right"
  (Republikaner/NPD/DVU) registers as essentially 0% in every ESS round
  2002-2009 (checked 2026-09-08: `pct_rightvote` = 0.00 for `btw` 2002,
  2005, 2009 in `essger.rds`), which is why 2013+ was tried first — 2013
  itself was later dropped too after checking the fitted models.
- **Survey weights**: not yet used in `clean_ess_ger_simple()`/
  `fit_model_ger_simple()` (a deliberately unweighted first model). ESS provides `pspwght`
  (post-stratification weight) and a derived `vote_weight` in `essger.rds`
  (construction TBD — trace and document here); see ANALYSIS_PLAN.md
  section 4 for the weighting approach once this moves beyond a first,
  simple model.
- **Missing data**: listwise deletion in `clean_ess_ger_simple()` (share
  dropped on `rightvote`, `worker`, `age_grp`, `gender`, `immigrant`, or
  `union` will differ slightly from the notebook's 12.7% now that the
  sample is 2017+2021 voters-only rather than 2013+ population-based) — a
  simplification to revisit with multiple imputation once the model
  specification is settled.

## Codebooks

Store the relevant ESS codebook excerpts / question wording for the variables
above in `data/codebooks/` (PDF or extracted text), so exact question wording
is preserved even if the ESS website changes.
