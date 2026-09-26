#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#| label: setup
#| echo: true
#| message: false
#| warning: false

if (!require("pacman")) {
  install.packages("pacman")
  library(pacman)
}
p_load(here, rio, brms, cmdstanr, tidybayes, ggdist, posterior, bayesplot, loo, marginaleffects, tinytable, tidyverse)

options(rio.import.trust = TRUE)

source(here("scripts", "_common.R"))

#
#
#
#
#
#
#
#| label: getdata
#| message: false

pb <- import(here("data", "processed", "pb7724.rds"))
pb_afd <- pb |>
  filter(year > 2012 & year < 2025)

#
#
#
#
#
#
#
#| label: sanitycheck
#| message: false

check_votes <- pb |>
filter(!is.na(pvote)) |>  # exclude missing vote intentions
count(year, pvote)  |>
group_by(year) |>
mutate(
vote_share = 100 * n / sum(n)
) |>
summarise(
total_share = sum(vote_share)
)

check_votes

#
#
#
#
#
#
#
#
#

pb |>
  filter(year > 2012) |>
  filter(!is.na(class)) |>
  group_by(year) |>
  summarise(mean_afd = weighted.mean(afd, weight_norm, na.rm = TRUE)) |>
  ggplot(aes(x = year, y = mean_afd))+
  geom_smooth()+
  theme_light()

pb |>
  filter(year > 2012) |>
  filter(!is.na(class)) |>
  group_by(year, class) |>
  summarise(mean_afd = weighted.mean(afd, weight_norm, na.rm = TRUE)) |>
  ggplot(aes(x = year, y = mean_afd, color = class))+
  geom_smooth()+
  theme_light()

pb |>
  filter(year > 2012) |>
  filter(!is.na(worker), !is.na(afd)) |>
  group_by(year, afd) |>
  summarise(mean_class = weighted.mean(worker, weight_norm, na.rm = TRUE)) |>
  ggplot(aes(x = year, y = mean_class, color = as.factor(afd)))+
  geom_smooth()+
  theme_light()

#
#
#
#
#
#
#

# The intercept has a prior centred on a log-odds of -2,
# corresponding to a baseline AfD probability of about 12%.
#
# The worker coefficient has a prior centred on zero, meaning
# that before seeing the data we do not assume that workers are
# more or less likely to support the AfD. The SD of 0.5 allows
# for meaningful but not extremely large differences.
#
# The exponential prior on the random-effect SDs constrains
# how much AfD support and the worker effect are allowed to vary
# across years.
#
# The LKJ prior favours modest correlations between the
# year-specific intercepts and worker effects.
priors_loyalty <- c(
  prior(normal(-2, 0.5), class = "Intercept"),
  prior(normal(0, 0.5), class = "b", coef = "worker"),
  prior(exponential(3), class = "sd"),
  prior(lkj(2), class = "cor")
)

# Aggregate the individual-level data into year × worker cells.
# For each year and worker category, count how many respondents
# did and did not report AfD vote intention.
# The resulting data can be analysed with a binomial likelihood:
# afd_1 = number supporting the AfD
# n_total = total number of respondents in the cell
pb_agg <- pb_afd |>
  count(year, worker, afd) |>
  tidyr::pivot_wider(names_from = afd, values_from = n, values_fill = 0,
                      names_prefix = "afd_") |>
  mutate(n_total = afd_0 + afd_1) |>
  filter(!is.na(worker))

# Fit the same basic hierarchical model that we intend to use
# later with the individual-level data.
#
# The model estimates AfD support as a function of worker status,
# while allowing both the overall level of AfD support and the
# worker effect to vary across years.
#
# sample_prior = "only" means that the observed data are NOT used
# to estimate the model. We draw exclusively from the specified
# prior distributions. This lets us see what kinds of predictions
# our priors imply before looking at the data.
m2a_prior_check <- brm(
  afd_1 | trials(n_total) ~ worker + (1 + worker | year),
  data         = pb_agg,
  family       = binomial(),
  prior        = priors_loyalty,
  backend      = "cmdstanr",
  threads      = threading(4),
  sample_prior = "only",   # draws from prior, ignores the likelihood entirely
  chains = 4, cores = 4, seed = 1
)

# Draw 2,000 prior-implied probabilities for each year and
# worker category. More draws give a smoother representation
# of the prior predictive distribution.
prior_pred <- pb_agg |>
  distinct(year, worker) |>
  mutate(n_total = 1) |>
  add_epred_draws(
    m2a_prior_check,
    ndraws = 2000
  )

# Plot the prior-implied probabilities and overlay the actual
# aggregate AfD proportions from the Politbarometer.
#
# The ribbons show what the model considers plausible before
# seeing the data; the white dots show what was actually observed.
#
# We want the observed proportions to fall comfortably within
# the prior predictive distribution, without the prior being so
# broad that virtually any conceivable AfD support level looks
# equally plausible.
ggplot(prior_pred, aes(x = year, y = .epred)) +
  stat_lineribbon(
    .width = c(.50, .80, .95)
  ) +
  geom_point(
    data = pb_agg,
    aes(
      x = year,
      y = afd_1 / n_total
    ),
    inherit.aes = FALSE,
    color = "white",
    size = 2
  ) +
  facet_wrap(~ worker) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(
    x = "Erhebungsjahr",
    y = "Pr(AfD | worker, year)"
  )

# Extract the simulated parameter draws from the prior-only model.
# This allows us to inspect the implied distributions of individual
# coefficients and random-effect parameters.
prior_draws <- as_draws_df(m2a_prior_check)

# Examine the prior for the worker effect on the odds-ratio scale.
#
# An odds ratio of 1 means no difference between workers and
# non-workers. Values above 1 imply higher AfD odds among workers,
# while values below 1 imply lower odds.
#
# This is easier to interpret substantively than the coefficient
# on the log-odds scale.
prior_draws |>
  ggplot(aes(x = exp(b_worker))) +
  stat_halfeye()

# Examine the prior distribution of the year-specific random
# intercept SD.
#
# This tells us how much year-to-year variation in the overall
# level of AfD support the prior considers plausible.
prior_draws |>
  ggplot(aes(x = sd_year__Intercept)) +
  stat_halfeye()

# Examine the prior distribution of the year-specific worker-effect SD.
#
# This tells us how much the difference between workers and
# non-workers is allowed to vary from one year to another.
prior_draws |>
  ggplot(aes(x = sd_year__worker)) +
  stat_halfeye()

# Focus on one year (2020) to inspect the prior distribution
# of the predicted AfD probability more closely.
#
# This makes it easier to see the full prior distribution for
# workers and non-workers without the additional visual complexity
# of the time dimension.
prior_pred |>
  filter(year == 2020) |>
  ggplot(aes(x = .epred)) +
  stat_halfeye() +
  facet_wrap(~ worker) +
  coord_cartesian(xlim = c(0, 1))

# Generate prior-predictive replicated AfD counts using the actual
# sample size of each year × worker cell.
#
# Unlike add_epred_draws(), this includes both uncertainty about
# the underlying probability and binomial sampling variation.
prior_y <- pb_agg |>
  add_predicted_draws(
    m2a_prior_check,
    ndraws = 2000
  ) |>
  mutate(
    p_afd = .prediction / n_total
  )

# Compare the distribution of prior-predictive AfD proportions
# with the actual observed proportions.
ggplot(prior_y, aes(x = p_afd)) +
  stat_halfeye() +
  facet_wrap(~ year)+
  theme_minimal()

#
#
#
#
#
#
#

priors_loyalty <- c(
  prior(normal(-2, 0.5), class = "Intercept"),
  prior(normal(0, 0.5), class = "b", coef = "worker"),
  prior(exponential(3), class = "sd"),
  prior(lkj(2), class = "cor")
)

m0 <- brm(afd | weights(weight_norm) ~ worker,
          data = pb_afd,
          family = bernoulli(),
          prior = priors_loyalty[1:2, ],
          chains = 4, cores = 4, seed = 1,
          iter = 1000, warmup = 500,
          backend      = "cmdstanr",
          threads      = threading(4),
          file = here("models", "pb_afd_loyal0"))

m1 <- brm(afd | weights(weight_norm) ~ worker + (1 | year),
          data = pb_afd, family = bernoulli(),
          prior = priors_loyalty[c(1,2,3), ],
          chains = 4, cores = 4, seed = 1,
          iter = 1000, warmup = 500,
          backend      = "cmdstanr",
          threads      = threading(4),
          file = here("models", "pb_afd_loyal1"))

m2a <- brm(afd | weights(weight_norm) ~ worker + (1 + worker | year),
           data = pb_afd, family = bernoulli(),
           prior = priors_loyalty,
           chains = 4, cores = 4, seed = 1,
          iter = 1000, warmup = 500,
           backend = "cmdstanr",
           threads = threading(4),
           file = here("models", "pb_afd_loyal2"))

# Rhat < 1.01, bulk/tail ESS for ALL params incl. group-level SDs
summary(m2a)
# binary DV, check calibration by year
pp_check(m2a)
loo_compare(loo(m0), loo(m1), loo(m2a))

#
#
#
#
#

icv_by_year <- pb_afd |>
  distinct(year) |>
  tidyr::crossing(worker = c(0, 1)) |>
  add_epred_draws(m2a) |>
  ungroup() |>
  select(-.row) |>
  pivot_wider(
    id_cols = c(year, .chain, .iteration, .draw),
    names_from = worker, values_from = .epred, names_prefix = "p_worker"
  ) |>
  mutate(icv = p_worker1 - p_worker0)

icv_by_year |>
  ggplot(aes(x = factor(year), y = icv)) +
  stat_gradientinterval()+
  geom_hline(yintercept = 0, linetype = "dashed",
             color = "#c3c2b7", linewidth = 0.4) +   # baseline/axis gray, not a data hue
  scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
  labs(
    x = NULL,
    y = "P(AfD | worker) − P(AfD | non-worker)",
    caption = "Posterior median, 66% and 95% credible intervals"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7")
  )

ggsave(here("figs", "class_gap_afd.png"),
       width = 10, height = 7, dpi = 300,
       bg = "white")

icv_by_year |>
  ggplot(aes(x = factor(year), y = p_worker1)) +
  stat_gradientinterval()+
  scale_y_continuous(limits = c(0, 0.7)) +
  labs(
    x = NULL,
    y = "P(AfD | worker)",
    caption = "Posterior median, 66% and 95% credible intervals"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7"),
    axis.text.x = element_text(angle = 90)
  )

ggsave(here("figs", "loyalty_worker_afd.png"),
      width = 10, height = 7, dpi = 300,
      bg = "white")


#
#
#
#
#
#
#
#
#

# The intercept describes the probability of being a worker when
# afd = 0 (the reference category).
#
# The AfD coefficient describes how the log-odds of being a worker
# change among AfD supporters relative to non-AfD respondents.
#
# The random-effect priors allow both the overall probability of
# being a worker and the AfD difference to vary across years.
priors_contribution <- c(
  prior(normal(-1.0, 0.5), class = "Intercept"),
  prior(normal(0, 1), class = "b", coef = "afd"),
  prior(exponential(3), class = "sd"),
  prior(lkj(2), class = "cor")
)

# Aggregate the individual-level data into year × AfD cells.
#
# For each year and AfD category, count how many respondents are
# workers and how many are not workers.
#
# This gives us the information needed to represent the individual-
# level Bernoulli outcome as a binomial outcome.
pb_agg_contrib <- pb_afd |>
  count(year, afd, worker) |>
  tidyr::pivot_wider(
    names_from = worker,
    values_from = n,
    values_fill = 0,
    names_prefix = "worker_"
  ) |>
  mutate(
    n_total = worker_0 + worker_1
  ) |>
  filter(!is.na(afd))

# Fit the reverse model using only the specified priors.
#
# sample_prior = "only" means that the observed aggregate data
# are NOT used to update the priors. The model therefore tells us
# what probabilities of being a worker the priors imply.
m2a_prior_check_contrib <- brm(
  worker_1 | trials(n_total) ~ afd + (1 + afd | year),
  data = pb_agg_contrib,
  family = binomial(),
  prior = priors_contribution,
  backend = "cmdstanr",
  threads = threading(4),
  sample_prior = "only",
  chains = 4,
  cores = 4,
  seed = 1
)

# Generate 2,000 prior-implied probabilities of being a worker
# for every year × AfD combination.
#
# n_total = 1 is used because we are interested in the underlying
# probability rather than in predicted numbers of workers.
prior_pred_contrib <- pb_agg_contrib |>
  distinct(year, afd) |>
  mutate(n_total = 1) |>
  add_epred_draws(
    m2a_prior_check_contrib,
    ndraws = 2000
  )

# Calculate weighted worker proportions for each year × AfD cell.
#
# These are the observed proportions corresponding to the weighted
# individual-level model that will be estimated later.
pb_weighted_contrib <- pb_afd |>
  filter(!is.na(worker), !is.na(afd)) |>
  group_by(year, afd) |>
  summarise(
    p_worker = weighted.mean(worker, weight, na.rm = TRUE),
    .groups = "drop"
  )

# Compare the prior-implied probabilities with the weighted
# empirical proportions that correspond to the final analysis.
ggplot(
  prior_pred_contrib,
  aes(x = year, y = .epred)
) +
  stat_lineribbon(
    .width = c(.50, .80, .95)
  ) +
  geom_point(
    data = pb_weighted_contrib,
    aes(
      x = year,
      y = p_worker
    ),
    inherit.aes = FALSE,
    color = "white",
    size = 2
  ) +
  facet_wrap(~ afd) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(
    x = "Erhebungsjahr",
    y = "Pr(Worker | AfD, year)"
  )+
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7")
  )
#
#
#

priors_contribution <- c(
  prior(normal(-1.0, 0.5), class = "Intercept"),
  prior(normal(0, 1), class = "b", coef = "afd"),
  prior(exponential(3), class = "sd"),
  prior(lkj(2), class = "cor")
)

m2a_contrib <- brm(
  worker | weights(weight_norm) ~ afd + (1 + afd | year),
  data = pb_afd, family = bernoulli(link = "logit"),
  prior = priors_contribution,
  backend = "cmdstanr",
  threads = threading(4),
  chains = 4, cores = 4, seed = 1,
  file = here("models", "pb_workers_afd_contrib"))

contribution_by_year <- pb_afd |>
  distinct(year) |>
  tidyr::crossing(afd = c(0, 1)) |>
  add_epred_draws(m2a_contrib) |>
  ungroup() |>
  select(-.row) |>
  pivot_wider(names_from = afd, values_from = .epred, names_prefix = "p_afd")

contribution_by_year |>
  ggplot(aes(x = factor(year), y = p_afd1)) +
  stat_gradientinterval()+
  scale_y_continuous(limits = c(0, 1))+
  labs(x = NULL,
  y = "Pr(worker | AfD)")+
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7")
  ) + 
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7")
  )

ggsave(here("figs", "contrib_workers_afd.png"),
       width = 10, height = 7, dpi = 300,
       bg = "white")
#
#
#
#
#
#
#

priors_worker_share <- c(
  prior(normal(0, 1.5), class = "Intercept"),
  prior(exponential(1), class = "sd")
)

m_worker_share <- brm(
  worker | weights(weight_norm) ~ 1 + (1 | year),
  data   = pb_afd,
  family = bernoulli(),
  prior  = priors_worker_share,
  backend = "cmdstanr",
  threads = threading(4),
  chains = 4, cores = 4, seed = 1,
  file = here("models", "pb_workers_share_1324")
)

worker_share_draws <- pb_afd |>
  distinct(year) |>
  add_epred_draws(m_worker_share) |>
  ungroup() |>
  rename(worker_share = .epred) |>
  select(year, .draw, worker_share)

pci_by_year <- pb_afd |>
  distinct(year) |>
  tidyr::crossing(afd = c(0, 1)) |>
  add_epred_draws(m2a_contrib) |>
  ungroup() |>
  select(-.row) |>
  pivot_wider(names_from = afd, values_from = .epred, names_prefix = "p_afd") |>
  left_join(worker_share_draws, by = c("year", ".draw")) |>
  mutate(pci = p_afd1 - worker_share)

pci_by_year |>
  ggplot(aes(x = factor(year), y = pci)) +
  stat_gradientinterval()+
  geom_hline(yintercept = 0, linetype = "dotted")+
  labs(x = NULL, y = "Party Cleavage Index") +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7")
  ) + 
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7")
  )

ggsave(here("figs", "pci_workers_afd.png"),
       width = 10, height = 7, dpi = 300,
       bg = "white")

#
#
#
#
#
#
#
#| label: worker_share_left

pb |>
  filter(!is.na(worker), !is.na(spd)) |>
  group_by(year, spd) |>
  summarise(mean_class = weighted.mean(worker, weight_norm, na.rm = TRUE)) |>
  ggplot(aes(x = year, y = mean_class, color = as.factor(spd)))+
  geom_smooth()+
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7")
  )

#
#
#
#
#
#
#

pb |>
  filter(!is.na(spd)) |>
  group_by(year) |>
  summarise(mean_spd = weighted.mean(spd, weight_norm, na.rm = TRUE)) |>
  ggplot(aes(x = year, y = mean_spd))+
  geom_smooth()+
  theme_light()

pb |>
  filter(!is.na(spd), !is.na(class)) |>
  group_by(year, class) |>
  summarise(mean_spd = weighted.mean(spd, weight_norm, na.rm = TRUE)) |>
  ggplot(aes(x = year, y = mean_spd, color = class))+
  geom_smooth()+
  theme_light()

#
#
#
#
#
#
#

# The intercept is the log-odds of SPD support among non-workers.
# Over 1977-2024 that probability moved from roughly 30-35% down to
# well under 20%; we centre the prior around a mid-range value
# (normal(-0.7, 0.75) implies a median of about 33%) and rely on
# the year random effects, not this fixed value, to trace the
# decline.
#
# The worker coefficient is centred on zero -- we do not assume a
# direction -- with an SD wide enough (0.75 vs. 0.5 for AfD) to
# accommodate the historically large class gap the SPD is known
# for as a traditional workers' party.
#
# The exponential rate on the random-effect SDs is lower here than
# for AfD (1.5 vs. 3): a 47-year span needs more room for the
# year-to-year level and slope to drift than a 12-year span does.
priors_loyalty_spd <- c(
  prior(normal(-0.7, 0.75), class = "Intercept"),
  prior(normal(0, 0.75),    class = "b", coef = "worker"),
  prior(exponential(1.5),   class = "sd"),
  prior(lkj(2),             class = "cor")
)

# Aggregate to year x worker cells, exactly as for the AfD model.
pb_agg_spd <- pb |>
  count(year, worker, spd) |>
  tidyr::pivot_wider(names_from = spd, values_from = n, values_fill = 0,
                      names_prefix = "spd_") |>
  mutate(n_total = spd_0 + spd_1) |>
  filter(!is.na(worker))

# Prior-only fit: draws exclusively from priors_loyalty_spd.
m_loyalty_prior_check_spd <- brm(
  spd_1 | trials(n_total) ~ worker + (1 + worker | year),
  data         = pb_agg_spd,
  family       = binomial(),
  prior        = priors_loyalty_spd,
  backend      = "cmdstanr",
  threads      = threading(4),
  sample_prior = "only",
  chains = 4, cores = 4, seed = 1
)

# Prior-implied probabilities for every year x worker combination,
# plotted against the actual aggregate SPD proportions -- the
# observed points should sit comfortably inside the prior bands
# across the full historical range, not just in recent years.

prior_pred_spd <- pb_agg_spd |>
  distinct(year, worker) |>
  mutate(n_total = 1) |>
  add_epred_draws(
    m_loyalty_prior_check_spd,
    ndraws = 2000
  )

ggplot(prior_pred_spd, aes(x = year, y = .epred)) +
  stat_lineribbon(
    .width = c(.50, .80, .95)
  ) +
  geom_point(
    data = pb_agg_spd,
    aes(
      x = year,
      y = spd_1 / n_total
    ),
    inherit.aes = FALSE,
    color = "white",
    size = 2
  ) +
  facet_wrap(~ worker) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(
    x = "Erhebungsjahr",
    y = "Pr(SPD | worker, year)"
  )

# Inspect individual prior components: the worker effect on the
# odds-ratio scale, and the two year-level random-effect SDs.
prior_draws_spd <- as_draws_df(m_loyalty_prior_check_spd)

prior_draws_spd |>
  ggplot(aes(x = exp(b_worker))) +
  stat_halfeye()

prior_draws_spd |>
  ggplot(aes(x = sd_year__Intercept)) +
  stat_halfeye()

prior_draws_spd |>
  ggplot(aes(x = sd_year__worker)) +
  stat_halfeye()

#
#
#
#
#
#

m_loyalty_spd <- brm(
  spd_1 | trials(n_total) ~ worker + (1 + worker | year),
  data         = pb_agg_spd,
  family       = binomial(),
  prior        = priors_loyalty_spd,
  backend      = "cmdstanr",
  threads      = threading(4),
  chains       = 4,
  cores        = 4,
  iter         = 2000,
  warmup       = 1000,
  seed         = 1
)

posterior_spd <- as_draws_df(m_loyalty_spd)

newdata_spd <- expand.grid(
  year = sort(unique(pb_agg_spd$year)),
  worker = c(0, 1),
  n_total = 1
)

posterior_spd <- m_loyalty_spd |>
  add_epred_draws(
    newdata = newdata_spd,
    re_formula = NULL
  )

ggplot(data = posterior_spd, aes(x = factor(year), y = .epred)) +
  stat_gradientinterval()


#
#
#
#
#
#
#

priors_loyalty_spd <- c(
  prior(normal(-0.7, 0.75), class = "Intercept"),
  prior(normal(0, 0.75),    class = "b", coef = "worker"),
  prior(exponential(1.5),   class = "sd"),
  prior(lkj(2),             class = "cor")
)

m0_spd <- brm(spd | weights(weight_norm) ~ worker,
              data = pb,
              family = bernoulli(),
              prior = priors_loyalty_spd[1:2, ],
              iter = 1000, warmup = 500,
              chains = 4, cores = 4, seed = 1,
              backend      = "cmdstanr",
              threads      = threading(4),
              file = here("models", "pb_spd_loyal0"))

m1_spd <- brm(spd | weights(weight_norm) ~ worker + (1 | year),
              data = pb,
              family = bernoulli(),
              prior = priors_loyalty_spd[c(1,2,3), ],
              iter = 1000, warmup = 500,
              chains = 4, cores = 4, seed = 1,
              backend      = "cmdstanr",
              threads      = threading(4),
              file = here("models", "pb_spd_loyal1"))

m2a_spd <- brm(spd | weights(weight_norm) ~ worker + (1 + worker | year),
               data = pb, 
               family = bernoulli(),
               prior = priors_loyalty_spd,
               chains = 4, cores = 4, seed = 1,
               iter = 1000, warmup = 500,
               backend = "cmdstanr",
               threads = threading(4),
               file = here("models", "pb_spd_loyal2"))

# Rhat < 1.01, bulk/tail ESS for ALL params incl. group-level SDs
summary(m2a_spd)
# binary DV, check calibration by year
pp_check(m2a_spd)
# loo_compare(loo(m0_spd), loo(m1_spd), loo(m2a_spd))

#
#
#
#
#

icv_by_year_spd <- pb |>
  distinct(year) |>
  tidyr::crossing(worker = c(0, 1)) |>
  add_epred_draws(m2a_spd) |>
  ungroup() |>
  select(-.row) |>
  pivot_wider(
    id_cols = c(year, .chain, .iteration, .draw),
    names_from = worker, values_from = .epred, names_prefix = "p_worker"
  ) |>
  mutate(icv = p_worker1 - p_worker0)

icv_by_year_spd |>
  ggplot(aes(x = factor(year), y = icv)) +
  stat_gradientinterval()+
  geom_hline(yintercept = 0, linetype = "dashed",
             color = "#c3c2b7", linewidth = 0.4) +
  scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
  labs(
    x = NULL,
    y = "P(SPD | worker) − P(SPD | non-worker)",
    caption = "Posterior median, 66% and 95% credible intervals"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7"),
    axis.text.x = element_text(angle = 90)
  )

ggsave(here("figs", "class_gap_spd.png"),
       width = 10, height = 7, dpi = 300,
       bg = "white")

icv_by_year_spd |>
  ggplot(aes(x = factor(year), y = p_worker1)) +
  stat_gradientinterval()+
  scale_y_continuous(limits = c(0, 0.7)) +
  labs(
    x = NULL,
    y = "P(SPD | worker)",
    caption = "Posterior median, 66% and 95% credible intervals"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7"),
    axis.text.x = element_text(angle = 90)
  )

ggsave(here("figs", "loyalty_worker_spd.png"),
      width = 10, height = 7, dpi = 300,
      bg = "white")

#
#
#
#
#
#
#
#
#

# The intercept describes the probability of being a worker among
# non-SPD respondents (spd = 0). The working-class share of the
# electorate started around 50% in the late 1970s and declined
# steadily since; centring the prior at logit(0.5) = 0 with an SD
# of 0.75 reflects that historical starting point while leaving
# room for the year random effects (with a correspondingly loose
# exponential(1.5) SD prior) to carry the decline.
#
# The SPD coefficient is centred on zero, with an SD wide enough to
# allow for the historically large gap in worker share between SPD
# and non-SPD respondents that the party's working-class base would
# imply.
priors_contribution_spd <- c(
  prior(normal(-0.8, 0.5), class = "Intercept"),
  prior(normal(0, 0.75),   class = "b", coef = "spd"),
  prior(exponential(3),    class = "sd"),
  prior(lkj(2),            class = "cor")
)

# Aggregate to year x SPD cells, exactly as for the AfD contribution model.
pb_agg_contrib_spd <- pb |>
  count(year, spd, worker) |>
  tidyr::pivot_wider(
    names_from = worker,
    values_from = n,
    values_fill = 0,
    names_prefix = "worker_"
  ) |>
  mutate(
    n_total = worker_0 + worker_1
  ) |>
  filter(!is.na(spd))

# Prior-only fit.
m_contrib_prior_check_spd <- brm(
  worker_1 | trials(n_total) ~ spd + (1 + spd | year),
  data = pb_agg_contrib_spd,
  family = binomial(),
  prior = priors_contribution_spd,
  backend = "cmdstanr",
  threads = threading(4),
  sample_prior = "only",
  chains = 4,  cores = 4,  seed = 1
)

# Prior-implied worker probabilities for every year x SPD combination.
prior_pred_contrib_spd <- pb_agg_contrib_spd |>
  distinct(year, spd) |>
  mutate(n_total = 1) |>
  add_epred_draws(
    m_contrib_prior_check_spd,
    ndraws = 2000
  )

# Weighted empirical worker shares for comparison.
pb_weighted_contrib_spd <- pb |>
  filter(!is.na(worker), !is.na(spd)) |>
  group_by(year, spd) |>
  summarise(
    p_worker = weighted.mean(worker, weight, na.rm = TRUE),
    .groups = "drop"
  )

ggplot(
  prior_pred_contrib_spd,
  aes(x = year, y = .epred)
) +
  stat_lineribbon(
    .width = c(.50, .80, .95)
  ) +
  geom_point(
    data = pb_weighted_contrib_spd,
    aes(
      x = year,
      y = p_worker
    ),
    inherit.aes = FALSE,
    color = "white",
    size = 2
  ) +
  facet_wrap(~ spd) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(
    x = "Erhebungsjahr",
    y = "Pr(Worker | SPD, year)"
  )+
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7")
  )

#
#
#

m_contrib_spd <- brm(
  worker | weights(weight_norm) ~ spd + (1 + spd | year),
  data = pb, family = bernoulli(link = "logit"),
  prior = priors_contribution_spd,
  backend = "cmdstanr",
  threads = threading(4),
  iter = 1000, warmup = 500,
  chains = 4, cores = 4, seed = 1,
  file = here("models", "pb_spd_contrib"))

contribution_by_year_spd <- pb |>
  distinct(year) |>
  tidyr::crossing(spd = c(0, 1)) |>
  add_epred_draws(m_contrib_spd) |>
  ungroup() |>
  select(-.row) |>
  pivot_wider(names_from = spd, values_from = .epred, names_prefix = "p_spd")

contribution_by_year_spd |>
  ggplot(aes(x = factor(year), y = p_spd1)) +
  stat_gradientinterval()+
  scale_y_continuous(limits = c(0, 1))+
  labs(x = NULL,
  y = "Pr(worker | SPD)")+
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7"),
    axis.text.x = element_text(angle = 90)
  )

ggsave(here("figs", "contrib_workers_spd.png"),
       width = 10, height = 7, dpi = 300,
       bg = "white")

#
#
#
#
#
#
#

priors_worker_share <- c(
  prior(normal(0, 1.5), class = "Intercept"),
  prior(exponential(1), class = "sd")
)

m_worker_share <- brm(
  worker | weights(weight_norm) ~ 1 + (1 | year),
  data   = pb,
  family = bernoulli(),
  prior  = priors_worker_share,
  backend = "cmdstanr",
  iter = 1000, warmup = 500,
  threads = threading(4),
  chains = 4, cores = 4, seed = 1,
  file = here("models", "pb_workers_share_7724")
)

worker_share_draws <- pb |>
  distinct(year) |>
  add_epred_draws(m_worker_share) |>
  ungroup() |>
  rename(worker_share = .epred) |>
  select(year, .draw, worker_share)

pci_by_year <- pb |>
  distinct(year) |>
  tidyr::crossing(spd = c(0, 1)) |>
  add_epred_draws(m_contrib_spd) |>
  ungroup() |>
  select(-.row) |>
  pivot_wider(names_from = spd, values_from = .epred, names_prefix = "p_spd") |>
  left_join(worker_share_draws, by = c("year", ".draw")) |>
  mutate(pci = p_spd1 - worker_share)

pci_by_year |>
  ggplot(aes(x = factor(year), y = pci)) +
  stat_gradientinterval()+
  geom_hline(yintercept = 0, linetype = "dotted")+
  labs(x = NULL, y = "Party Cleavage Index") +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "#c3c2b7"),
    axis.text.x = element_text(angle = 90)
  )

ggsave(here("figs", "pci_workers_spd.png"),
       width = 10, height = 7, dpi = 300,
       bg = "white")

#
#
#
pb_cells <- pb |>
  filter(!is.na(worker), !is.na(spd), !is.na(weight)) |>
  group_by(year, worker) |>
  summarise(
    p = weighted.mean(spd, weight),
    n = n(),
    weight_sum = sum(weight),
    n_eff = weight_sum^2 / sum(weight^2),
    .groups = "drop"
  )

pb_cells |> tt()
#
#
#
#
#
#
#
#| label: scatter-year-summaries

# Summarise one posterior quantity by year: median and 80% interval.
summarise_year <- function(data, var, prefix) {
  data |>
    group_by(year) |>
    summarise(
      "{prefix}_med" := median({{ var }}),
      "{prefix}_lo"  := quantile({{ var }}, 0.10),
      "{prefix}_hi"  := quantile({{ var }}, 0.90),
      .groups = "drop"
    )
}

afd_years <- sort(unique(pb_afd$year))

scatter_year <- list(
  summarise_year(icv_by_year, p_worker1, "afd_loyalty"),
  summarise_year(contribution_by_year, p_afd1, "afd_contrib"),
  summarise_year(filter(icv_by_year_spd, year %in% afd_years),
                 p_worker1, "spd_loyalty"),
  summarise_year(filter(contribution_by_year_spd, year %in% afd_years),
                 p_spd1, "spd_contrib")
) |>
  reduce(inner_join, by = "year") |>
  arrange(year)

scatter_year |>
  select(year, ends_with("_med")) |>
  tt(digits = 3)

# Common scatter-plot template (years instead of countries)
year_scatter <- function(data, x, y, x_lo, x_hi, y_lo, y_hi,
                         xlab, ylab, diagonal = FALSE) {
  p <- ggplot(data, aes(x = {{ x }}, y = {{ y }}))

  if (diagonal) {
    p <- p + geom_abline(intercept = 0, slope = 1,
                         linetype = "dashed", colour = "grey60")
  }

  p +
    geom_errorbar(aes(xmin = {{ x_lo }}, xmax = {{ x_hi }}),
                  width = 0, orientation = "y", colour = "grey70") +
    geom_errorbar(aes(ymin = {{ y_lo }}, ymax = {{ y_hi }}),
                  width = 0, colour = "grey70") +
    # Connect the years in chronological order
    geom_path(colour = "grey40", linewidth = 0.3) +
    geom_point(size = 2.5) +
    # Use ggrepel for non-overlapping labels if it is installed
    {
      if (requireNamespace("ggrepel", quietly = TRUE)) {
        ggrepel::geom_text_repel(aes(label = year), size = 3.5, seed = 2026,
                                 max.overlaps = Inf)
      } else {
        geom_text(aes(label = year), vjust = -0.9, size = 3.5)
      }
    } +
    scale_x_continuous(labels = scales::label_percent(accuracy = 1)) +
    scale_y_continuous(labels = scales::label_percent(accuracy = 1)) +
    labs(
      x = xlab,
      y = ylab,
      caption = "Posterior medians with 80% credible intervals"
    )
}

#
#
#
#
#
#
#
#| label: scatter-loyalty-spd-afd

year_scatter(
  scatter_year,
  x = spd_loyalty_med, y = afd_loyalty_med,
  x_lo = spd_loyalty_lo, x_hi = spd_loyalty_hi,
  y_lo = afd_loyalty_lo, y_hi = afd_loyalty_hi,
  xlab = "Loyalty: P(SPD | worker)",
  ylab = "Loyalty: P(AfD | worker)",
  diagonal = TRUE
)

ggsave(here("figs", "scatter_loyalty_spd_afd.png"),
       width = 8, height = 7, dpi = 300,
       bg = "white")

#
#
#
#
#
#
#
#| label: scatter-contribution-spd-afd

year_scatter(
  scatter_year,
  x = spd_contrib_med, y = afd_contrib_med,
  x_lo = spd_contrib_lo, x_hi = spd_contrib_hi,
  y_lo = afd_contrib_lo, y_hi = afd_contrib_hi,
  xlab = "Contribution: P(worker | SPD)",
  ylab = "Contribution: P(worker | AfD)",
  diagonal = TRUE
)

ggsave(here("figs", "scatter_contribution_spd_afd.png"),
       width = 8, height = 7, dpi = 300,
       bg = "white")

#
#
#
#
#
#

priors_loyalty_cl <- c(
  prior(normal(-0.7, 0.5), class = "Intercept"),
  prior(normal(0, 0.75),   class = "b", coef = "worker"),
  prior(exponential(2),    class = "sd"),
  prior(lkj(2),            class = "cor")
)

pb_agg_fixed <- pb |>
  filter(!is.na(worker)) |>
  filter(v4a == 2) |> 
  group_by(year, intmonth) |>
  mutate(weight_norm = pwght / mean(pwght)) |>
  ungroup() |>
  group_by(year, worker) |>
  summarise(
    n_success = round(sum(weight_norm * centerleft)),
    n_total   = round(sum(weight_norm)),
    .groups = "drop"
  )

pb_cl_agg <- brm(
  n_success | trials(n_total) ~ worker + (1 + worker | year),
  data    = pb_agg_fixed,
  family  = binomial(),
  prior   = priors_loyalty_cl,
  chains  = 4, cores = 4, seed = 1,
  iter    = 1000, warmup = 500,
  backend = "cmdstanr",
  file    = here("models", "pb_cl_loyal_agg")
)

posterior_cl <- as_draws_df(pb_cl_agg)

newdata_cl <- expand.grid(
  year = sort(unique(pb_agg_fixed$year)),
  worker = c(0, 1),
  n_total = 1
)

posterior_cl <- pb_cl_agg |>
  add_epred_draws(
    newdata = newdata_cl,
    re_formula = NULL
  )

ggplot(data = posterior_cl, aes(x = factor(year), y = .epred)) +
  stat_halfeye()

#
#
#
