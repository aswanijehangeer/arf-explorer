# Exercise the actual Shiny server, including generation and result invalidation.
if (!requireNamespace("shiny", quietly = TRUE) ||
    !requireNamespace("arf", quietly = TRUE)) stop("Install shiny and arf first.")

app_environment <- new.env(parent = globalenv())
previous_dir <- getwd()
setwd(file.path("inst", "shiny"))
tryCatch(sys.source("app.R", envir = app_environment),
         finally = setwd(previous_dir))

shiny::testServer(app_environment$server, {
  session$setInputs(dataset = "dependency", seed = 42L, n_synth = 100L,
                    num_trees = 10L, min_node_size = 5L,
                    metric = "KS", explore_variable = "x",
                    evaluate_variable = "x", explore_x = "x", explore_y = "y",
                    explore_colour = "segment", evaluate_x = "x", evaluate_y = "y",
                    evaluate_colour = "segment")
  session$flushReact()
  stopifnot(is.null(result()), nrow(partitions()$holdout) > 0L)
  session$setInputs(generate = 1L)
  session$flushReact()
  stopifnot(!is.null(result()), nrow(result()$synthetic) == 100L,
            setequal(unique(scores()$source),
                     c("ARF", "Independent columns", "Real training")),
            all(is.finite(scores()$value)))
  for (id in c("profile", "synthetic_preview", "scores", "dependence_scores",
               "accuracy", "compare_distribution", "compare_relationship")) {
    stopifnot(!is.null(output[[id]]))
  }
  session$setInputs(evaluate_variable = "segment", metric = "TVD")
  session$flushReact()
  stopifnot(!is.null(output$compare_distribution), !is.null(output$scores))
  session$setInputs(min_node_size = 10L)
  session$flushReact()
  stopifnot(is.null(result()))
})
cat("Shiny generation, numerical/categorical rendering, and setting invalidation passed.\n")
