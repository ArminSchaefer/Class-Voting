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
- **Worker / non-worker** (used in `scripts/analyze_ess_ger.qmd`): `worker =
  1` if `class5 %in% c(4, 5)` ("Skilled workers", "Low-skilled workers"),
  `0` if `class5 %in% c(1, 2, 3)` ("Higher-grade service class",
  "Lower-grade service class", "Small business"), else `NA`. This is the
  classic manual-worker definition (Alford's "manual workers"); ~16% of
  `essger.rds` (4,518 / 28,547) have `class5 = NA` (occupational class
  unavailable, typically respondents outside the labour force) and are
  dropped by listwise deletion in that script.
- **Radical-right party vote** (used in `scripts/analyze_ess_ger.qmd`):
  `rightvote = 1` if `pvote_non_voter == "radical right"`, `0` for every
  other category (including `"nonvoter"`), based on the existing
  `pvote`/`pvote_non_voter` party-family coding already present in
  `essger.rds`. **TBD**: document here which per-country party
  classification produced `pvote`/`pvote_non_voter` (own coding? PopuList?
  ParlGov?) and its version/date — not yet traced in this file. For Germany
  this resolves to the AfD from 2013 onward; pre-2013 "radical right"
  (Republikaner/NPD/DVU) registers as essentially 0% in every ESS round
  2002-2009 (checked 2026-09-08: `pct_rightvote` = 0.00 for `btw` 2002,
  2005, 2009 in `essger.rds`) — **`scripts/analyze_ess_ger.qmd` therefore
  restricts the German model to `btw >= 2013`**; pooling all 11 rounds would
  build a model on three elections in which the outcome was structurally
  near-impossible.
- **Survey weights**: not yet used in `scripts/analyze_ess_ger.qmd` (a
  deliberately unweighted first model). ESS provides `pspwght`
  (post-stratification weight) and a derived `vote_weight` in `essger.rds`
  (construction TBD — trace and document here); see ANALYSIS_PLAN.md
  section 4 for the weighting approach once this moves beyond a first,
  simple model.
- **Missing data**: listwise deletion in `scripts/analyze_ess_ger.qmd`
  (12.7% of the 2013+, Germany-only sample dropped on `rightvote`, `worker`,
  `age_grp`, `gender`, `immigrant`, or `union`) — a simplification to
  revisit with multiple imputation once the model specification is settled.

## Codebooks

Store the relevant ESS codebook excerpts / question wording for the variables
above in `data/codebooks/` (PDF or extracted text), so exact question wording
is preserved even if the ESS website changes.
