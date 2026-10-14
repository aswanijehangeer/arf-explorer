# Run this from the extracted arfexplorer project folder.
required <- c("shiny", "arf")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install dependencies first: install.packages(c('shiny', 'arf'))",
       call. = FALSE)
}
shiny::runApp(file.path("inst", "shiny"), launch.browser = interactive())

