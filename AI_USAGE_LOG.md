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
