\name{evaluate_columns}
\alias{evaluate_columns}
\title{Compare Empirical Univariate Distributions}
\usage{evaluate_columns(reference, comparison)}
\arguments{
  \item{reference}{A nonempty data frame of numerical and categorical columns.}
  \item{comparison}{A nonempty data frame with matching column names and types.}
}
\description{Calculates the empirical KS statistic and one-dimensional
Wasserstein distance for numerical columns and total variation distance for
categorical columns. Smaller values mean closer empirical distributions.}
\details{Missing values are excluded from distribution scores and their rates
are reported separately. Infinite numerical values are also excluded; excluded
rates include all excluded observations. Category labels are aligned across
datasets, including categories seen in only one dataset. No hypothesis test
p-values, privacy guarantees, or combined quality score are produced.
Wasserstein distances have the original variable's units.}
\value{A long data frame containing variable, metric, value, effective sample
sizes, missing rates, and excluded rates. Scores with no usable observations
are returned as \code{NA}.}
\examples{evaluate_columns(iris[1:75, ], iris[76:150, ])}

