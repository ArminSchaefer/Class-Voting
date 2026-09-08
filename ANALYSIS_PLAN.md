# Analysis Plan: From Bayes' Rule to Bayesian Estimation

This document operationalizes the manuscript's unwritten final section,
"From Bayes' rule to Bayesian estimation." It should be updated *before*
model specifications change, not after (write-ahead, not write-after), so it
functions as a running preregistration and keeps the workflow auditable.

## 1. Estimands

For group *g* (worker/non-worker) and party *j* (radical-right/other), by
country *c* and ESS round *r*:

- **Loyalty** (voter perspective): `Pr(vote_j | group_g, c, r)`
- **Contribution** (party perspective): `Pr(group_g | vote_j, c, r)`
- **ICV**: `Pr(vote_j | worker, c, r) - Pr(vote_j | ~worker, c, r)`
- **PCI**: `Pr(worker | vote_j, c, r) - Pr(worker, c, r)`

Each of these is currently computed in the manuscript as a **point estimate**
from cross-tabulated proportions. The Bayesian extension below produces a
**posterior distribution** for each, by country and round, so that (a)
sampling uncertainty from finite survey N is represented, and (b) partial
pooling stabilizes estimates in small country-round cells.

## 2. Generative model

Likelihood (individual level, i in country c, round r):

```
vote_rr_i ~ Bernoulli(p_i)
logit(p_i) = alpha + alpha_c[c] + alpha_r[r] + (beta + beta_c[c]) * worker_i
```

- `alpha_c[c] ~ Normal(0, sigma_c)` — country varying intercept
- `alpha_r[r] ~ Normal(0, sigma_r)` (or a random-walk / AR(1) over ordered
  rounds if a smooth time trend is theoretically preferred to exchangeable
  round effects — decide based on how many rounds are included and whether a
  trend, not just round-to-round variation, is the object of interest)
- `beta_c[c] ~ Normal(0, sigma_beta)`, optionally correlated with `alpha_c[c]`
  via an LKJ prior on the group-level correlation matrix — this is the
  hierarchical version of the Alford/ICV quantity: `beta + beta_c[c]` *is*
  the country-specific ICV on the logit scale.

This is a **descriptive/associational** model (Pr(vote | worker), not a causal
effect of an intervention on "worker status"). State this explicitly in the
manuscript; do not use causal language for `beta` without a design that
supports it (see Statistical Rigor note below).

## 3. Priors

Weakly informative by default, to be checked via prior predictive simulation
before fitting to real data:

| Parameter        | Prior                | Rationale |
|------------------|-----------------------|-----------|
| Intercept        | `Normal(0, 1.5)`      | On the logit scale, allows RR vote shares roughly in [0.01, 0.99] a priori |
| `beta` (worker)  | `Normal(0, 1)`        | Weakly regularizes toward no effect; a logit-scale effect of |1| already implies a substantial swing |
| `sigma_c`, `sigma_r`, `sigma_beta` | `Exponential(1)` (or `Half-Normal`) | Standard weakly-informative choice for group-level SDs in brms/Stan workflows |
| Group-level correlation | `LKJ(2)` | Mildly skeptical of extreme correlations between intercept and slope |

Action item: run `brms::brm(..., sample_prior = "only")` and inspect
`pp_check()` on the **prior** predictive distribution before touching real
data, to confirm these are not accidentally informative given the actual
scale of RR vote shares across ESS countries (which range roughly from near
0% to >25%).

## 4. Survey weighting

ESS weights (`dweight`, `pspwght`, `anweight`) reflect unequal selection
probabilities and post-stratification adjustments. Two documented options,
in order of preference:

1. **Pseudo-likelihood weighting**: pass weights via brms's `weights()`
   addition term. This is an approximation (it does not have a fully
   generative justification the way the likelihood above does) and must be
   reported as such, not silently treated as exact Bayesian inference.
2. **Weights as auxiliary information in a multilevel structure**: if design
   effects are driven by known strata (e.g. region within country), consider
   modeling those strata as an additional grouping factor instead of / in
   addition to weighting, which is more consistent with a fully generative
   Bayesian approach.

Decide and document the choice here before fitting M1+; run key models both
weighted and unweighted as a sensitivity check regardless of which is
reported as primary.

## 5. Model sequence and comparison

| Model | Structure | Purpose |
|-------|-----------|---------|
| M0 | Pooled logistic regression | Baseline, no hierarchical structure |
| M1 | + varying intercepts by country and round | Partial pooling on baseline RR support |
| M2 | + varying slope for `worker` by country | Country-specific ICV (the manuscript's core quantity), partially pooled |

Compare via `loo::loo_compare()` (ELPD differences with SE), not raw
log-likelihood or WAIC alone. Report Rhat (< 1.01) and bulk/tail ESS for all
parameters, not just fixed effects. Run `pp_check()` with test statistics
relevant to a binary DV (e.g. proportion positive, by country) in addition to
the default density overlay.

## 6. From posterior to indices

For the chosen model (expected: M2), draw from the posterior predictive /
expected-value distribution (`tidybayes::add_epred_draws()` or
`brms::posterior_epred()`) to get, **for every posterior draw**, the implied
`Pr(vote_rr | worker, c, r)` and `Pr(vote_rr | ~worker, c, r)`. Apply the
closed-form `icv()`, `contribution()`, and `pci()` functions
(`R/functions_derive.R`) to each draw. The result is a full posterior
distribution of each index, by country and round, summarized with medians and
66%/95% credible intervals (`ggdist::stat_halfeye()` plots rather than only
point estimates + SEs). `Pr(worker, c, r)` should itself be estimated with
uncertainty from the same survey (e.g. via `survey`/`srvyr`), not treated as
a fixed known quantity, unless a decision is made and documented to use an
external register-based figure instead.

## 7. Sensitivity analyses (report in `reports/`)

- Refit M2 under at least one materially different prior (e.g. `Normal(0,2.5)`
  on `beta`) — report whether posterior conclusions on the ICV/PCI change.
- Refit with and without survey weights (see Section 4).
- Refit excluding any country with very small n\* for the RR party being
  studied where the small-cell instability the manuscript flags for the
  Alford index (e.g. very small workforce shares) could otherwise be mistaken
  for a substantive finding rather than partial-pooling behavior.

## 8. Manuscript integration

`manuscript.qmd` should call `targets::tar_read(posterior_indices)` etc.
rather than recomputing model fits inline, so the rendered manuscript is
guaranteed to match the pipeline's current state. Report point estimates as
posterior medians with credible intervals throughout Section "From Bayes'
rule to Bayesian estimation," and explicitly contrast the closed-form (point
estimate) ICV/ACI/PCI already in the manuscript against their fully Bayesian
posterior counterparts, since that contrast is the paper's contribution.

## 9. Using AI in this workflow

See `AI_USAGE_LOG.md` for the transparency log. Division of labor:

**Delegate to AI (draft, then verify by running it yourself):**
- Boilerplate R functions (import/clean/model/plot) against a specified
  interface (see stubs in `R/`)
- brms formula and prior candidates, for your review — not final decisions
- Diagnostic code (`pp_check`, `loo`, `posterior::summarise_draws`)
- Unit tests reproducing closed-form worked examples (see
  `tests/testthat/test-indices.R`, which reproduces the manuscript's own
  1957 SPD example as a regression test)
- Drafting prose for methods sections, once results are finalized
- Code review of pipeline changes; checking algebraic rewrites (e.g.
  confirming a rearranged Bayes' rule expression is equivalent to the
  original)

**Do not delegate:**
- Which occupations count as "worker" and which parties count as "radical
  right" in each country — substantive, theory-laden coding decisions
- Final prior choices — AI can propose defaults, but justification should
  rest on your domain knowledge of plausible RR vote-share ranges
- Whether a model "ran successfully" — always inspect `summary()`,
  `pp_check()`, and Rhat/ESS yourself; do not accept an AI's claim that
  code executed without error unless you have run it
- Causal interpretation of results
- Citation content — verify every reference against the original source;
  do not let AI fabricate bibliographic details
