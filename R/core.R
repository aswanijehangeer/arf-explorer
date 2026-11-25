# Keep data preparation, generation, and metrics independent of the Shiny UI.

.with_seed <- function(seed, code) {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(seed)
  force(code)
}

.whole_number <- function(x, name, lower, upper) {
  if (length(x) != 1L || !is.numeric(x) || !is.finite(x) ||
      x != floor(x) || x < lower || x > upper) {
    stop(name, " must be a whole number between ", lower, " and ", upper,
         ".", call. = FALSE)
  }
  as.integer(x)
}

.validate_pair <- function(reference, comparison) {
  if (!is.data.frame(reference) || !is.data.frame(comparison) ||
      nrow(reference) == 0L || nrow(comparison) == 0L ||
      ncol(reference) == 0L || !identical(names(reference), names(comparison))) {
    stop("Use nonempty data frames with the same column names and order.",
         call. = FALSE)
  }
  for (name in names(reference)) {
    r <- reference[[name]]
    s <- comparison[[name]]
    cat_r <- is.factor(r) || is.character(r) || is.logical(r)
    cat_s <- is.factor(s) || is.character(s) || is.logical(s)
    if (!((is.numeric(r) && is.numeric(s)) || (cat_r && cat_s))) {
      stop("Unsupported or inconsistent types for column: ", name,
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

demo_data <- function(choice = "dependency") {
  if (identical(choice, "iris")) return(datasets::iris)
  if (!identical(choice, "dependency")) stop("Unknown demo dataset.")
  .with_seed(73, {
    n <- 420L
    segment <- sample(c("A", "B", "C"), n, replace = TRUE,
                      prob = c(0.4, 0.35, 0.25))
    centres <- c(A = -1.5, B = 0, C = 1.5)
    x <- stats::rnorm(n, mean = unname(centres[segment]), sd = 0.45)
    y <- 0.75 * x + stats::rnorm(n, sd = 0.35)
    status <- ifelse(stats::runif(n) < stats::plogis(0.8 * x), "Yes", "No")
    data.frame(x = x, y = y, segment = factor(segment),
               status = factor(status, levels = c("No", "Yes")))
  })
}

split_demo <- function(data, seed = 42L) {
  seed <- .whole_number(seed, "seed", 0, 1000000)
  categorical <- names(data)[vapply(data, is.factor, logical(1))]
  strata <- if (length(categorical)) data[[categorical[1L]]] else
    rep("all", nrow(data))
  indices <- split(seq_len(nrow(data)), strata)
  train_ids <- .with_seed(seed, {
    unlist(lapply(indices, function(ids) {
      n <- length(ids)
      if (n < 2L) stop("Each stratum needs at least two observations.")
      size <- max(1L, min(n - 1L, floor(0.8 * n)))
      ids[sample.int(n, size)]
    }), use.names = FALSE)
  })
  list(training = data[sort(train_ids), , drop = FALSE],
       holdout = data[setdiff(seq_len(nrow(data)), train_ids), , drop = FALSE])
}

column_profile <- function(data) {
  data.frame(
    Variable = names(data),
    Type = vapply(data, function(x) if (is.numeric(x)) "Numeric" else
      "Categorical", character(1)),
    Missing = vapply(data, function(x) sum(is.na(x)), integer(1)),
    Distinct = vapply(data, function(x) length(unique(x[!is.na(x)])), integer(1)),
    row.names = NULL, check.names = FALSE
  )
}

# Empirical 1D Wasserstein distance: integral of the absolute CDF difference.
# Unequal sample sizes and ties are supported; units match the original column.
.numeric_distances <- function(r, s) {
  r <- r[is.finite(r)]
  s <- s[is.finite(s)]
  if (!length(r) || !length(s)) return(c(KS = NA_real_, Wasserstein = NA_real_))
  grid <- sort(unique(c(r, s)))
  differences <- abs(stats::ecdf(r)(grid) - stats::ecdf(s)(grid))
  wasserstein <- if (length(grid) == 1L) 0 else
    sum(differences[-length(grid)] * diff(grid))
  c(KS = max(differences), Wasserstein = wasserstein)
}

.categorical_tvd <- function(r, s) {
  r <- as.character(r[!is.na(r)])
  s <- as.character(s[!is.na(s)])
  if (!length(r) || !length(s)) return(NA_real_)
  categories <- sort(unique(c(r, s)))
  p <- as.numeric(table(factor(r, levels = categories))) / length(r)
  q <- as.numeric(table(factor(s, levels = categories))) / length(s)
  0.5 * sum(abs(p - q))
}

#' Compare empirical univariate distributions
#' @param reference A nonempty reference data frame.
#' @param comparison A data frame with matching names and column types.
#' @return A long data frame of KS statistics, empirical Wasserstein distances,
#'   and categorical total variation distances. Missing rates are reported
#'   separately; distribution scores exclude missing values.
#' @export
evaluate_columns <- function(reference, comparison) {
  .validate_pair(reference, comparison)
  rows <- lapply(names(reference), function(name) {
    r <- reference[[name]]
    s <- comparison[[name]]
    if (is.numeric(r)) {
      distances <- .numeric_distances(r, s)
      valid_r <- is.finite(r)
      valid_s <- is.finite(s)
    } else {
      distances <- c(TVD = .categorical_tvd(r, s))
      valid_r <- !is.na(r)
      valid_s <- !is.na(s)
    }
    data.frame(
      variable = name, metric = names(distances), value = unname(distances),
      reference_n = sum(valid_r), comparison_n = sum(valid_s),
      reference_missing_rate = mean(is.na(r)),
      comparison_missing_rate = mean(is.na(s)),
      reference_excluded_rate = mean(!valid_r),
      comparison_excluded_rate = mean(!valid_s), stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}

numeric_dependence <- function(reference, comparison) {
  .validate_pair(reference, comparison)
  columns <- names(reference)[vapply(reference, is.numeric, logical(1))]
  if (length(columns) < 2L) return(data.frame())
  pairs <- utils::combn(columns, 2L, simplify = FALSE)
  correlation <- function(data, pair) {
    x <- data[[pair[1L]]]
    y <- data[[pair[2L]]]
    ok <- is.finite(x) & is.finite(y)
    if (sum(ok) < 3L || stats::sd(x[ok]) == 0 || stats::sd(y[ok]) == 0)
      return(NA_real_)
    stats::cor(x[ok], y[ok], method = "pearson")
  }
  do.call(rbind, lapply(pairs, function(pair) {
    a <- correlation(reference, pair)
    b <- correlation(comparison, pair)
    data.frame(pair = paste(pair, collapse = " / "), reference = a,
               comparison = b, absolute_difference = abs(a - b),
               stringsAsFactors = FALSE)
  }))
}

generate_demo <- function(training, n_synth = 300L, seed = 42L,
                          num_trees = 30L, min_node_size = 5L,
                          progress = function(value, detail) NULL) {
  n_synth <- .whole_number(n_synth, "n_synth", 2, 5000)
  seed <- .whole_number(seed, "seed", 0, 1000000)
  num_trees <- .whole_number(num_trees, "num_trees", 10, 200)
  min_node_size <- .whole_number(min_node_size, "min_node_size", 2, 25)
  .validate_pair(training, training)
  if (anyNA(training)) stop("This first generation demo expects complete data.")
  if (!requireNamespace("arf", quietly = TRUE)) {
    stop("Install the arf package first: install.packages('arf').")
  }
  started <- proc.time()[["elapsed"]]
  model_result <- .with_seed(seed, {
    progress(0.1, "Learning partitions with adversarial_rf()")
    logs <- utils::capture.output({
      forest <- arf::adversarial_rf(
        training, num_trees = num_trees, min_node_size = min_node_size,
        max_iters = 5L, early_stop = TRUE, parallel = FALSE,
        verbose = TRUE
      )
    })
    progress(0.5, "Fitting leaf distributions with forde()")
    params <- arf::forde(forest, training, parallel = FALSE)
    progress(0.8, "Sampling synthetic rows with forge()")
    synthetic <- as.data.frame(arf::forge(params, n_synth = n_synth,
                                         parallel = FALSE))
    .validate_pair(training, synthetic)
    list(synthetic = synthetic, accuracy = as.numeric(forest$acc), logs = logs)
  })
  elapsed <- proc.time()[["elapsed"]] - started
  shuffled <- .with_seed(seed + 1L, {
    out <- training[rep(1L, n_synth), , drop = FALSE]
    for (name in names(training)) {
      out[[name]] <- training[[name]][sample.int(nrow(training), n_synth,
                                                replace = TRUE)]
    }
    rownames(out) <- NULL
    out
  })
  progress(1, "Ready to compare against the untouched holdout")
  c(model_result, list(shuffled = shuffled, elapsed = elapsed,
                       n_synth = n_synth, seed = seed,
                       num_trees = num_trees, min_node_size = min_node_size,
                       max_iters = 5L))
}

#' Launch the introductory Shiny demonstration
#' @param ... Arguments passed to shiny::runApp().
#' @export
run_demo <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Install shiny first: install.packages('shiny').")
  }
  app_dir <- system.file("shiny", package = "arfexplorer", mustWork = TRUE)
  shiny::runApp(app_dir, ...)
}

