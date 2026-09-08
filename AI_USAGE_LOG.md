# AI Usage Log

A running, transparent record of AI-assisted work on this project, kept for
disclosure purposes (OUP and most journals now expect this) and so that any
AI-drafted code or text is traceable to when and why it was introduced.

Convention: add an entry whenever AI substantially drafted code, text, or
analysis logic that entered the repository (a one-line autocomplete does not
need an entry; a generated function, model specification, or paragraph does).
Reference the git commit hash once committed.

| Date | Tool | What was AI-assisted | Human verification performed | Commit |
|------|------|----------------------|-------------------------------|--------|
| 2026-09-08 | Claude (Sonnet) | Initial project scaffold: folder structure, `_targets.R` skeleton, `R/` function stubs (unimplemented, `stop()`-guarded), `.gitignore`, `DATA_PROVENANCE.md` / `ANALYSIS_PLAN.md` templates, and `tests/testthat/test-indices.R` (which reproduces the manuscript's own 1957 SPD worked example as a numeric regression test for `icv()`/`contribution()`/`pci()`) | Closed-form index functions checked by hand against manuscript.qmd's worked example; all other functions are intentionally unimplemented stubs, not run | *(pending first commit)* |
| 2026-09-08 | Claude (Sonnet) | Drafted `scripts/analyze_ess_ger.qmd`: a single-country (Germany), non-hierarchical Bayesian logistic regression of `rightvote` on `worker`, `age_grp`, `gender`, `immigrant`, `union`, with priors developed from real AfD national vote shares (not from the analysis sample) and checked via prior predictive simulation | Data-construction and prior-predictive chunks were actually executed against the real staged `essger.rds` in a verification sandbox (all numbers in the notebook's prose are live output, not invented); the `brm()`/diagnostics/posterior chunks are marked `eval: false` because no Stan toolchain was available to compile/fit them there — they still need to be run and inspected locally before trusting any posterior result. Also discovered and documented (in DATA_PROVENANCE.md) that pre-2013 ESS rounds have ~0% radical-right vote in this data (AfD founded 2013), motivating the `btw >= 2013` sample restriction | *(pending commit)* |
