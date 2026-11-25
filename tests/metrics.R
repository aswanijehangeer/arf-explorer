# Small, analytical checks of statistical edge cases; no extra test dependency.
if (requireNamespace("arfexplorer", quietly = TRUE)) {
  metrics <- arfexplorer::evaluate_columns
} else {
  source(file.path("R", "core.R"))
  metrics <- evaluate_columns
}
get_score <- function(x, metric) x$value[x$metric == metric]
same <- metrics(data.frame(x = c(0, 0, 2)), data.frame(x = c(0, 0, 2)))
stopifnot(all(same$value == 0))

# Unequal sample sizes: each unit of probability is one unit from the target.
unequal <- metrics(data.frame(x = c(0, 2)), data.frame(x = 1))
stopifnot(abs(get_score(unequal, "Wasserstein") - 1) < 1e-12,
          abs(get_score(unequal, "KS") - 0.5) < 1e-12)
reverse <- metrics(data.frame(x = 1), data.frame(x = c(0, 2)))
stopifnot(isTRUE(all.equal(unequal$value, reverse$value)))

# Disjoint categories must be aligned by label rather than factor codes.
categorical <- metrics(
  data.frame(g = factor(c("A", "A"), levels = c("B", "A"))),
  data.frame(g = factor(c("B", "B"), levels = c("A", "B"))))
stopifnot(get_score(categorical, "TVD") == 1)
half <- metrics(data.frame(g = c("A", "A")), data.frame(g = c("A", "B")))
stopifnot(get_score(half, "TVD") == 0.5)

# Constant columns, missing-only columns, and infinite numerical values.
constant <- metrics(data.frame(x = c(7, 7)), data.frame(x = c(7, 7, 7)))
stopifnot(all(constant$value == 0))
missing_only <- metrics(data.frame(x = c(NA_real_, NA_real_)), data.frame(x = 1))
stopifnot(all(is.na(missing_only$value)),
          all(missing_only$reference_missing_rate == 1))
excluded <- metrics(data.frame(x = c(0, Inf, NA_real_)), data.frame(x = 0))
stopifnot(all(excluded$value == 0),
          all(excluded$reference_n == 1),
          all(excluded$reference_excluded_rate == 2/3))

# An incompatible column must fail instead of being silently recoded.
bad <- try(metrics(data.frame(x = 1), data.frame(x = "1")), silent = TRUE)
stopifnot(inherits(bad, "try-error"))
cat("All analytical metric checks passed.\n")

