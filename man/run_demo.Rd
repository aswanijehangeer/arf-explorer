\name{run_demo}
\alias{run_demo}
\title{Launch the Introductory Shiny Demonstration}
\usage{run_demo(...)}
\arguments{\item{...}{Arguments passed to \code{shiny::runApp()}.}}
\description{Explore mixed tabular data, generate synthetic data using
\pkg{arf}, and compare empirical distributions against an untouched holdout.}
\value{The result of \code{shiny::runApp()}, called for its interactive side effect.}
\examples{if (interactive() && requireNamespace("shiny", quietly = TRUE) &&
    requireNamespace("arf", quietly = TRUE)) run_demo()}

