# Validation completed during preparation

Date: 2026-10-14. Environment: Linux, R 4.3.3, official CRAN `arf` 0.2.5.
The Shiny application uses the real ARF pipeline, with no substitute generator
or simulated metric results.

| Check | Result |
|---|---|
| Analytical univariate metric checks | Passed |
| ARF training -> FORDE -> FORGE on the dependency example | Passed |
| ARF training -> FORDE -> FORGE on Iris | Passed |
| Repeat generation with the same seed | Identical generated data in both datasets |
| Training/holdout disjointness | Passed |
| Actual Shiny server generation | Passed using `shiny::testServer()` |
| Numerical and categorical plot/table rendering | Passed using `shiny::testServer()` |
| Changing experiment settings clears previous results | Passed |
| `R CMD build --no-build-vignettes` | Passed |
| `R CMD check --no-manual` | Status: OK; no errors, warnings, or notes |

Metric checks cover identical distributions, unequal sample sizes, symmetry,
category-label alignment, unseen categories, constant columns, missing-only
columns, infinite numerical values, and incompatible types.

ARF smoke runs used 100 synthetic rows, 10 trees, minimum leaf size 5, seed 42,
and a limit of five adversarial rounds. Serial execution is used in this demo.

The server test executes generation, reads the rendered plot/table outputs,
switches from a numerical column to a categorical column, and changes a model
setting to verify that stale results are cleared.

These checks do not include an interactive visual inspection in a live browser,
Windows/macOS execution, PDF-manual building, or CRAN submission. They also do
not validate the prototype as a comprehensive research evaluation framework.
Contributor metadata remains a placeholder for discussion and later replacement.
