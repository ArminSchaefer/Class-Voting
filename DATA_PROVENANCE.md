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

- **Worker / non-worker**: TBD — e.g. based on ISCO-08 occupation codes
  (`isco08`) mapped to ESeC or EGP class categories; specify which occupations
  are "worker" and cite the coding scheme.
- **Radical-right party vote**: TBD — per-country party coding for `prtvt*`
  (country-specific vote variables); specify which classification you use
  (e.g. PopuList, ParlGov, Chapel Hill Expert Survey) and its version/date.
- **Survey weights**: TBD — ESS provides `dweight` (design weight),
  `pspwght` (post-stratification weight), and `anweight` (analysis weight =
  `pspwght` x population size, for pooling across countries). State which
  weight is used where and why (see ANALYSIS_PLAN.md, "Survey weighting").
- **Missing data**: TBD — listwise deletion vs. imputation; if imputation,
  specify method and packages.

## Codebooks

Store the relevant ESS codebook excerpts / question wording for the variables
above in `data/codebooks/` (PDF or extracted text), so exact question wording
is preserved even if the ESS website changes.
