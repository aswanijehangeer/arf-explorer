# Run after installing shiny and arf, from the project folder.
source(file.path("R", "core.R"))
source(file.path("tests", "metrics.R"))
for (choice in c("dependency", "iris")) {
  data <- demo_data(choice)
  split <- split_demo(data, seed = 42L)
  stopifnot(length(intersect(rownames(split$training), rownames(split$holdout))) == 0L,
            nrow(split$training) + nrow(split$holdout) == nrow(data))
  result <- generate_demo(split$training, n_synth = 100L, num_trees = 10L)
  stopifnot(nrow(result$synthetic) == 100L, nrow(result$shuffled) == 100L,
            identical(names(result$synthetic), names(data)),
            length(result$accuracy) >= 1L,
            all(is.finite(evaluate_columns(split$holdout, result$synthetic)$value)))
  again <- generate_demo(split$training, n_synth = 100L, num_trees = 10L)
  stopifnot(identical(result$synthetic, again$synthetic))
  cat("ARF pipeline and reproducibility passed for", choice, "\n")
}
if (!requireNamespace("shiny", quietly = TRUE)) stop("Install shiny to check the UI.")
app <- shiny::shinyAppDir(file.path("inst", "shiny"))
stopifnot(inherits(app, "shiny.appobj"))
cat("Shiny app directory recognized. Run scripts/server-smoke.R to exercise the server.\n")
