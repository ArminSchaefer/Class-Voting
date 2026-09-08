# ---------------------------------------------------------------------------
# Data import
#
# ESS microdata may not be redistributed (see DATA_PROVENANCE.md), so this
# function reads from a local, git-ignored copy in data/raw/. Consider the
# `essurvey` package (Cimentada) for a reproducible, script-based download
# against the ESS API using a personal access token, rather than a manual
# point-and-click export -- that way the download step itself is code, not
# a one-off manual action nobody can rerun.
# ---------------------------------------------------------------------------

#' Import raw ESS round(s) from a local file.
#'
#' @param path Path to a local raw-data file (see DATA_PROVENANCE.md for
#'   which rounds/countries/edition this is expected to contain).
#' @return A data frame / tibble of raw ESS microdata, unmodified.
import_ess <- function(path) {
  # TODO: e.g.
  #   essurvey::import_rounds(rounds = c(...), ess_email = Sys.getenv("ESS_EMAIL"))
  # or:
  #   haven::read_sav(path)
  stop("import_ess(): not yet implemented -- see DATA_PROVENANCE.md for source.")
}
