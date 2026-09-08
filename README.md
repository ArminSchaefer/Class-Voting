# Voting for a Party and Contributing to a Party's Vote — A Unified Bayesian Account

Research project on cleavage voting: the relationship between being a worker
and voting for a radical-right (RR) party, examined from both directions at
once via Bayes' rule.

- **Voter perspective**: Pr(RR vote | worker)
- **Party perspective**: Pr(worker | RR vote)

`manuscript/manuscript.qmd` shows that Alford's (1962) Index of Class Voting
(ICV), Axelrod's (1972) Contribution Index (ACI), and Hooghe & Marks' (2025)
Party Cleavage Index (PCI) are all re-expressions of Bayes' rule applied to a
group-membership x party-choice table. This project extends that from
closed-form point estimates to a **fully Bayesian estimation workflow**, so
every index carries a posterior distribution rather than a single number.

See `ANALYSIS_PLAN.md` for the statistical workflow (likelihood, priors,
model sequence, diagnostics) and `DATA_PROVENANCE.md` for the data source.

## Project structure

```
.
├── _targets.R              # pipeline definition (the single source of truth
│                            #   for how raw data becomes figures/tables/models)
├── R/                       # function library, sourced by _targets.R
│   ├── functions_import.R      # read raw ESS files
│   ├── functions_clean.R       # harmonize country/round/class/party coding
│   ├── functions_derive.R      # closed-form ICV / ACI / PCI (Bayes' rule)
│   ├── functions_model.R       # brms model specifications (M0 -> M2)
│   ├── functions_posterior.R   # posterior-draw versions of ICV / ACI / PCI
│   ├── functions_diagnostics.R # convergence + posterior predictive checks
│   └── functions_plot.R        # figures and tables
├── data/
│   ├── raw/                 # untouched ESS downloads — NEVER committed to git
│   ├── processed/           # cleaned, analysis-ready .rds files
│   └── codebooks/           # ESS variable documentation you rely on
├── models/                  # fitted brmsfit objects (.rds) — not committed to git
├── figs/                    # exported figures (deterministic filenames)
├── tables/                  # exported tables (gt / modelsummary output)
├── reports/                 # rendered supplementary analyses (prior/posterior
│                            #   predictive checks, sensitivity analyses)
├── manuscript/
│   ├── manuscript.qmd
│   └── literature.bib       # NOT YET CREATED — see note below
├── tests/testthat/          # unit tests for R/ functions
├── scripts/                 # one-off exploratory scripts (not part of the pipeline)
├── DATA_PROVENANCE.md
├── ANALYSIS_PLAN.md
├── AI_USAGE_LOG.md
└── .gitignore
```

## Reproducing the analysis

Once data and R are in place:

```r
# one-time setup
install.packages("renv")
renv::init()        # detects packages used across the project and locks them
renv::snapshot()     # writes renv.lock

# every subsequent run
renv::restore()      # installs exactly the locked package versions
targets::tar_make()  # (re-)runs the full pipeline: import -> clean -> model -> figures
targets::tar_visnetwork()  # inspect the pipeline DAG
```

`manuscript/manuscript.qmd` should read its inputs via `targets::tar_read()`
rather than recomputing them, so the rendered document is always in sync with
the pipeline (see ANALYSIS_PLAN.md, "Manuscript integration").

## Outstanding setup items

- [ ] `manuscript/literature.bib` does not exist yet. The manuscript cites
      Alford 1962/1967, Axelrod 1972, Hooghe & Marks 2025, Marks et al. 2023,
      Inglehart 1986, Clark 1991/2001, Dalton 2002, Gingrich 2015, Evans 2000,
      van der Waal 2007, and Hout 2010 — none are yet in a `.bib` file, so the
      document will not currently render with citations. Recommend building
      this via Zotero/BibDesk (with DOIs) rather than hand-typed entries.
- [ ] Run `renv::init()` in R/RStudio on this machine (R is not available in
      the sandbox that created this scaffold, so it could not be run here).
- [ ] `git init` has been run and this scaffold committed; connect to a
      remote (GitHub/GitLab/JGU GitLab) when ready to back it up / collaborate.
- [ ] Decide and document (in DATA_PROVENANCE.md) exactly which ESS rounds,
      countries, and RR-party classification you are using.
