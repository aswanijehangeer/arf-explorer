library(shiny)

# Support both a downloaded source project and an installed companion package.
if (file.exists(file.path("..", "..", "R", "core.R"))) {
  demo <- new.env(parent = baseenv())
  sys.source(file.path("..", "..", "R", "core.R"), envir = demo)
} else if (requireNamespace("arfexplorer", quietly = TRUE)) {
  demo <- asNamespace("arfexplorer")
} else {
  stop(
    "Run this app from the complete arfexplorer project or install that package."
  )
}

palette <- c("#087F8C", "#D97706", "#7656A5", "#BE4B5B", "#5B7C3B")
card <- function(title, ...) {
  div(class = "demo-card", h3(title), ...)
}

ui <- fluidPage(
  tags$head(
    tags$title("ARF Explorer | Explore, Generate, Evaluate"),
    tags$meta(
      name = "viewport",
      content = "width=device-width, initial-scale=1"
    ),
    tags$style(HTML(
      "
      body{background:#f5f7f8;color:#213345;font-family:system-ui,sans-serif;}
      .container-fluid{max-width:1440px;margin:auto;padding:24px;}
      .hero{padding:14px 0 24px;}
      .eyebrow{color:#087f8c;font-size:12px;letter-spacing:1.4px;font-weight:700;}
      .hero h1{font-size:34px;font-weight:750;letter-spacing:-.8px;margin-top:8px;}
      .hero p{font-size:16px;color:#5d6e7c;max-width:830px;}
      .well,.demo-card{background:white;border:1px solid #dde5e9;border-radius:12px;
        box-shadow:none;padding:20px;margin-bottom:18px;}
      .well h3{font-size:19px;margin-top:0;}
      .demo-card h3{font-size:19px;margin:0 0 13px;font-weight:650;}
      .demo-card h4{font-size:16px;font-weight:650;}
      .btn-primary{background:#087f8c;border-color:#087f8c;}
      #generate{width:100%;padding:12px;font-size:15px;font-weight:650;}
      .nav-tabs{border-bottom:1px solid #d9e2e6;margin-bottom:20px;}
      .nav-tabs>li>a{color:#536878;padding:12px 20px;font-weight:650;}
      .nav-tabs>li.active>a{color:#087f8c;border-radius:8px 8px 0 0;}
      .help-block,.muted{color:#647785;font-size:13px;}
      .sample-size{display:flex;gap:16px;padding:10px 0 16px;}
      .sample-size strong{display:block;font-size:25px;color:#17384a;}
      .sample-size span{display:block;color:#647785;font-size:12px;}
      .table-container{overflow:auto;}
      table{font-size:13px;}
      .callout{border-left:3px solid #087f8c;background:#eff8f8;padding:13px 15px;
        border-radius:0 6px 6px 0;margin-bottom:15px;line-height:1.55;}
      .placeholder{padding:22px;background:#f5f8fa;border-radius:8px;color:#5e7180;}
      .footnote{color:#657784;font-size:12px;padding:8px 2px 20px;}
      .step-code{font-family:monospace;font-size:14px;color:#087f8c;}
      @media(max-width:767px){.container-fluid{padding:12px;}.hero h1{font-size:27px;}}
    "
    ))
  ),
  div(
    class = "hero",
    div(class = "eyebrow", "ARF EXPLORER"),
    h1("Explore. Generate. Evaluate."),
    p(
      "Learn how adversarial random forests generate mixed tabular data, ",
      "then compare distributions and relationships with a held-out reference."
    )
  ),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h3("Your experiment"),
      selectInput(
        "dataset",
        "Demonstration dataset",
        choices = c(
          "Simulated dependency example" = "dependency",
          "Iris: measurements + species" = "iris"
        )
      ),
      uiOutput("sample_sizes"),
      numericInput(
        "seed",
        "Random seed",
        value = 42,
        min = 0,
        max = 1000000,
        step = 1
      ),
      sliderInput(
        "n_synth",
        "Synthetic rows",
        min = 100,
        max = 1000,
        value = 300,
        step = 50
      ),
      sliderInput(
        "num_trees",
        "Trees per forest",
        min = 10,
        max = 100,
        value = 30,
        step = 10
      ),
      sliderInput(
        "min_node_size",
        "Minimum real rows per leaf",
        min = 2,
        max = 20,
        value = 5,
        step = 1
      ),
      helpText(
        "Training is limited to five adversarial rounds. The holdout is ",
        "excluded from ARF fitting and from independent column sampling."
      ),
      actionButton("generate", "Generate & compare", class = "btn-primary"),
      hr(),
      uiOutput("run_summary"),
      p(
        class = "muted",
        "Changing an experiment setting clears the previous run. ",
        "Generate again to compare the new setting."
      )
    ),
    mainPanel(
      width = 9,
      tabsetPanel(
        id = "stage",
        tabPanel(
          "Explore",
          div(
            class = "callout",
            strong("Start with relationships. "),
            "Two tables can have similar column distributions while having ",
            "very different combinations of values."
          ),
          card(
            "Dataset and column types",
            uiOutput("dataset_note"),
            div(class = "table-container", tableOutput("profile")),
            div(class = "table-container", tableOutput("training_preview"))
          ),
          card(
            "One column at a time",
            selectInput("explore_variable", "Column", choices = NULL),
            plotOutput("explore_distribution", height = "270px")
          ),
          card(
            "Two numerical columns, coloured by category",
            fluidRow(
              column(
                4,
                selectInput("explore_x", "Horizontal axis", choices = NULL)
              ),
              column(
                4,
                selectInput("explore_y", "Vertical axis", choices = NULL)
              ),
              column(4, selectInput("explore_colour", "Colour", choices = NULL))
            ),
            plotOutput("explore_relationship", height = "300px")
          )
        ),
        tabPanel(
          "Generate",
          card(
            "The three ARF stages",
            fluidRow(
              column(
                4,
                p(class = "step-code", "adversarial_rf()"),
                p(
                  "Learn partitions by distinguishing real from synthetic rows."
                )
              ),
              column(
                4,
                p(class = "step-code", "forde()"),
                p(
                  "Fit numerical distributions and category probabilities inside leaves."
                )
              ),
              column(
                4,
                p(class = "step-code", "forge()"),
                p("Sample synthetic rows from the fitted distributions.")
              )
            ),
            p(
              class = "muted",
              "The second generator independently samples each ",
              "training column. It provides a simple baseline that loses dependencies."
            )
          ),
          card(
            "Discriminator accuracy during ARF training",
            uiOutput("generation_prompt"),
            plotOutput("accuracy", height = "260px"),
            p(
              class = "muted",
              "For balanced real/synthetic classes, 50% is chance ",
              "accuracy. Early stopping or the iteration limit can also end training. ",
              "This curve is a training diagnostic."
            )
          ),
          card(
            "Generated ARF rows",
            div(class = "table-container", tableOutput("synthetic_preview")),
            downloadButton("download_synthetic", "Download ARF data (CSV)")
          )
        ),
        tabPanel(
          "Evaluate",
          uiOutput("evaluation_prompt"),
          card(
            "Column distributions against the holdout",
            selectInput("evaluate_variable", "Column", choices = NULL),
            plotOutput("compare_distribution", height = "330px"),
            p(
              class = "muted",
              "All three panels use the same axes. Numerical plots ",
              "show empirical cumulative distributions; categorical plots show proportions."
            )
          ),
          card(
            "Univariate distances",
            selectInput(
              "metric",
              "Metric",
              choices = c(
                "KS statistic: numeric" = "KS",
                "Wasserstein: numeric, original units" = "Wasserstein",
                "Total variation distance: categorical" = "TVD"
              )
            ),
            uiOutput("metric_explanation"),
            div(class = "table-container", tableOutput("scores")),
            p(
              class = "muted",
              "ARF and independent sampling are evaluated against ",
              "the same holdout. Real training vs holdout is a real-versus-real baseline. ",
              "It is a contextual comparison, not a significance threshold."
            ),
            downloadButton("download_scores", "Download comparisons (CSV)")
          ),
          card(
            "Are relationships preserved?",
            fluidRow(
              column(
                4,
                selectInput("evaluate_x", "Horizontal axis", choices = NULL)
              ),
              column(
                4,
                selectInput("evaluate_y", "Vertical axis", choices = NULL)
              ),
              column(
                4,
                selectInput("evaluate_colour", "Colour", choices = NULL)
              )
            ),
            plotOutput("compare_relationship", height = "330px"),
            h4("Numerical Pearson correlations"),
            div(class = "table-container", tableOutput("dependence_scores")),
            p(
              class = "muted",
              "Correlations cover numerical pairs only. The coloured ",
              "plots also help inspect relationships with a categorical variable."
            )
          )
        )
      ),
      p(
        class = "footnote",
        "This first demo evaluates distributional resemblance. ",
        "Downstream utility, missing-data workflows and privacy attacks are possible extensions. ",
        "It is a companion prototype using arf, with no upstream package changes."
      )
    )
  )
)

server <- function(input, output, session) {
  result <- reactiveVal(NULL)
  data <- reactive(demo$demo_data(input$dataset))
  partitions <- reactive(demo$split_demo(data(), input$seed))

  observeEvent(
    list(
      input$dataset,
      input$seed,
      input$n_synth,
      input$num_trees,
      input$min_node_size
    ),
    {
      result(NULL)
    },
    ignoreInit = TRUE
  )

  observeEvent(
    input$dataset,
    {
      current <- data()
      numeric_names <- names(current)[vapply(current, is.numeric, logical(1))]
      category_names <- names(current)[vapply(current, is.factor, logical(1))]
      for (id in c("explore_variable", "evaluate_variable")) {
        updateSelectInput(
          session,
          id,
          choices = names(current),
          selected = names(current)[1L]
        )
      }
      for (prefix in c("explore", "evaluate")) {
        updateSelectInput(
          session,
          paste0(prefix, "_x"),
          choices = numeric_names,
          selected = numeric_names[1L]
        )
        updateSelectInput(
          session,
          paste0(prefix, "_y"),
          choices = numeric_names,
          selected = numeric_names[2L]
        )
        updateSelectInput(
          session,
          paste0(prefix, "_colour"),
          choices = category_names,
          selected = category_names[1L]
        )
      }
    },
    ignoreInit = FALSE
  )

  output$sample_sizes <- renderUI({
    x <- partitions()
    div(
      class = "sample-size",
      div(strong(nrow(x$training)), span("training rows")),
      div(strong(nrow(x$holdout)), span("holdout rows"))
    )
  })
  output$dataset_note <- renderUI({
    if (input$dataset == "dependency") {
      p(
        "This complete simulated table contains two numerical variables and ",
        "two categories. Its designed relationships make it useful for learning."
      )
    } else {
      p(
        "Iris contains four numerical flower measurements and one categorical ",
        "species column. This demo uses a stratified 80/20 split."
      )
    }
  })
  output$profile <- renderTable(demo$column_profile(data()), rownames = FALSE)
  output$training_preview <- renderTable(
    utils::head(partitions()$training, 6L),
    digits = 3,
    rownames = FALSE
  )

  draw_distribution <- function(values, title) {
    if (is.numeric(values)) {
      graphics::hist(
        values,
        breaks = "FD",
        col = palette[1L],
        border = "white",
        main = title,
        xlab = "Value",
        ylab = "Rows"
      )
    } else {
      p <- prop.table(table(values))
      graphics::barplot(
        p,
        col = palette[1L],
        border = NA,
        main = title,
        xlab = "Category",
        ylab = "Proportion",
        ylim = c(0, 1)
      )
    }
  }
  output$explore_distribution <- renderPlot({
    req(input$explore_variable)
    draw_distribution(
      partitions()$training[[input$explore_variable]],
      paste("Training:", input$explore_variable)
    )
  })

  category_colours <- function(values, levels) {
    colours <- rep(palette, length.out = length(levels))
    colours[match(as.character(values), levels)]
  }
  draw_relationship <- function(
    d,
    x,
    y,
    colour,
    title,
    xlim = NULL,
    ylim = NULL
  ) {
    levels <- levels(data()[[colour]])
    colours <- category_colours(d[[colour]], levels)
    graphics::plot(
      d[[x]],
      d[[y]],
      col = grDevices::adjustcolor(colours, alpha.f = 0.65),
      pch = 16,
      cex = 0.7,
      main = title,
      xlab = x,
      ylab = y,
      xlim = xlim,
      ylim = ylim
    )
    graphics::legend(
      "topleft",
      legend = levels,
      col = rep(palette, length.out = length(levels)),
      pch = 16,
      bty = "n",
      cex = 0.7
    )
  }
  output$explore_relationship <- renderPlot({
    req(input$explore_x, input$explore_y, input$explore_colour)
    draw_relationship(
      partitions()$training,
      input$explore_x,
      input$explore_y,
      input$explore_colour,
      "Training relationships"
    )
  })

  observeEvent(input$generate, {
    result(NULL)
    tryCatch(
      {
        generated <- withProgress(
          message = "Generating synthetic data",
          value = 0,
          {
            demo$generate_demo(
              partitions()$training,
              n_synth = input$n_synth,
              seed = input$seed,
              num_trees = input$num_trees,
              min_node_size = input$min_node_size,
              progress = function(value, detail) {
                setProgress(value = value, detail = detail)
              }
            )
          }
        )
        result(generated)
        updateTabsetPanel(session, "stage", selected = "Evaluate")
        showNotification(
          "Generation complete. Compare ARF, independent sampling and the real baseline.",
          type = "message",
          duration = 5
        )
      },
      error = function(e) {
        showNotification(conditionMessage(e), type = "error", duration = NULL)
      }
    )
  })
  output$run_summary <- renderUI({
    x <- result()
    if (is.null(x)) {
      return(p(class = "muted", "Ready for your first run."))
    }
    tagList(
      strong("Last completed run"),
      p(
        class = "muted",
        sprintf(
          "%s rows | %s trees | seed %s | %.2f seconds",
          x$n_synth,
          x$num_trees,
          x$seed,
          x$elapsed
        )
      )
    )
  })
  prompt <- function() {
    div(
      class = "placeholder",
      "Choose your settings, then click Generate & compare."
    )
  }
  output$generation_prompt <- renderUI(if (is.null(result())) prompt())
  output$evaluation_prompt <- renderUI(if (is.null(result())) prompt())
  output$accuracy <- renderPlot({
    req(result())
    acc <- result()$accuracy
    validate(need(
      length(acc) > 0,
      "No training accuracy was returned by this arf version."
    ))
    graphics::plot(
      seq_along(acc) - 1L,
      acc,
      type = "b",
      pch = 16,
      col = palette[1L],
      ylim = c(0, 1),
      xlab = "Adversarial round (initial classifier = 0)",
      ylab = "Out-of-bag accuracy",
      main = "ARF training diagnostic"
    )
    graphics::abline(h = 0.5, lty = 2, col = "#7c8a94")
  })
  output$synthetic_preview <- renderTable(
    {
      req(result())
      utils::head(result()$synthetic, 8L)
    },
    digits = 3,
    rownames = FALSE
  )

  comparisons <- reactive({
    req(result())
    list(
      "ARF" = result()$synthetic,
      "Independent columns" = result()$shuffled,
      "Real training" = partitions()$training
    )
  })
  scores <- reactive({
    sets <- comparisons()
    do.call(
      rbind,
      lapply(names(sets), function(name) {
        out <- demo$evaluate_columns(partitions()$holdout, sets[[name]])
        out$source <- name
        out
      })
    )
  })
  output$metric_explanation <- renderUI({
    explanation <- switch(
      input$metric,
      KS = "Largest absolute gap between empirical cumulative distributions. Range 0-1; smaller means closer.",
      Wasserstein = "Average transport distance between empirical numerical distributions. Original variable units; smaller means closer. Compare a column across generators, rather than averaging different columns.",
      TVD = "Half the sum of absolute category-proportion differences. Range 0-1; smaller means closer."
    )
    p(explanation)
  })
  output$scores <- renderTable(
    {
      out <- scores()
      out <- out[out$metric == input$metric, , drop = FALSE]
      data.frame(
        Source = out$source,
        Variable = out$variable,
        Distance = out$value,
        Holdout_n = out$reference_n,
        Comparison_n = out$comparison_n,
        check.names = FALSE
      )
    },
    digits = 4,
    rownames = FALSE
  )
  output$dependence_scores <- renderTable(
    {
      sets <- comparisons()
      out <- do.call(
        rbind,
        lapply(names(sets), function(name) {
          x <- demo$numeric_dependence(partitions()$holdout, sets[[name]])
          data.frame(
            Source = name,
            Pair = x$pair,
            Holdout = x$reference,
            Comparison = x$comparison,
            Absolute_gap = x$absolute_difference,
            check.names = FALSE
          )
        })
      )
      out
    },
    digits = 3,
    rownames = FALSE
  )

  output$compare_distribution <- renderPlot({
    req(result(), input$evaluate_variable)
    variable <- input$evaluate_variable
    ref <- partitions()$holdout[[variable]]
    sets <- comparisons()
    old <- graphics::par(mfrow = c(1, 3), mar = c(4, 4, 3, 1))
    on.exit(graphics::par(old))
    if (is.numeric(ref)) {
      limits <- range(c(ref, unlist(lapply(sets, function(d) d[[variable]]))))
      for (name in names(sets)) {
        graphics::plot(
          stats::ecdf(ref),
          xlim = limits,
          ylim = c(0, 1),
          main = name,
          xlab = variable,
          ylab = "Cumulative proportion",
          col = "#213345",
          verticals = TRUE,
          do.points = FALSE
        )
        graphics::lines(
          stats::ecdf(sets[[name]][[variable]]),
          col = palette[1L],
          verticals = TRUE,
          do.points = FALSE
        )
        graphics::legend(
          "bottomright",
          c("Holdout", "Comparison"),
          col = c("#213345", palette[1L]),
          lty = 1,
          bty = "n",
          cex = 0.75
        )
      }
    } else {
      categories <- sort(unique(c(
        as.character(ref),
        unlist(lapply(sets, function(d) as.character(d[[variable]])))
      )))
      proportions <- function(v) {
        as.numeric(table(factor(as.character(v), levels = categories))) /
          length(v)
      }
      for (name in names(sets)) {
        heights <- rbind(
          proportions(ref),
          proportions(sets[[name]][[variable]])
        )
        graphics::barplot(
          heights,
          beside = TRUE,
          names.arg = categories,
          col = c("#213345", palette[1L]),
          ylim = c(0, 1),
          main = name,
          ylab = "Proportion",
          cex.names = 0.75
        )
        graphics::legend(
          "topright",
          c("Holdout", "Comparison"),
          fill = c("#213345", palette[1L]),
          bty = "n",
          cex = 0.7
        )
      }
    }
  })
  output$compare_relationship <- renderPlot({
    req(result(), input$evaluate_x, input$evaluate_y, input$evaluate_colour)
    sets <- list(
      "Holdout" = partitions()$holdout,
      "ARF" = result()$synthetic,
      "Independent columns" = result()$shuffled
    )
    x <- input$evaluate_x
    y <- input$evaluate_y
    xlim <- range(unlist(lapply(sets, function(d) d[[x]])))
    ylim <- range(unlist(lapply(sets, function(d) d[[y]])))
    old <- graphics::par(mfrow = c(1, 3), mar = c(4, 4, 3, 1))
    on.exit(graphics::par(old))
    for (name in names(sets)) {
      draw_relationship(
        sets[[name]],
        x,
        y,
        input$evaluate_colour,
        name,
        xlim,
        ylim
      )
    }
  })
  output$download_synthetic <- downloadHandler(
    filename = function() {
      paste0("arf_", input$dataset, "_seed", input$seed, ".csv")
    },
    content = function(file) {
      req(result())
      utils::write.csv(result()$synthetic, file, row.names = FALSE)
    }
  )
  output$download_scores <- downloadHandler(
    filename = function() {
      paste0("comparisons_", input$dataset, "_seed", input$seed, ".csv")
    },
    content = function(file) {
      out <- scores()
      out$dataset <- input$dataset
      out$seed <- result()$seed
      out$num_trees <- result()$num_trees
      out$min_node_size <- result()$min_node_size
      out$max_iters <- result()$max_iters
      utils::write.csv(out, file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)
