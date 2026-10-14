**# ARF Explorer: an introductory Shiny prototype**

A small companion project demonstrating the **Explore → Generate → Evaluate** workflow using the real `arf` package. It is intended as a practical demonstration of the workflow, without modifying `arf`, implementing a comprehensive evaluation framework, or implying upstream endorsement.

**## Run the source project**

You need R >= 4.1.0. RStudio is convenient but optional. Extract the archive, open the `arfexplorer` folder, and make it your working directory.

In the R console:

```r
install.packages(c("shiny", "arf")) # Once, if not already installed
source("run.R")
```

Alternatively, run `Rscript run.R` from a terminal in this folder, then open the local URL printed by Shiny. No web deployment is needed for a meeting demo.

**## What to demonstrate**

1. Choose **Simulated dependency example**. It has numerical `x` and `y`, a three-level `segment`, and a binary `status` variable. The relationships are deliberately designed to make the difference between marginal and joint structure visible. This dataset is simulated, not a real patient dataset.
2. In **Explore**, inspect column types, a column distribution, and the plot of `x` against `y` coloured by `segment`.
3. Click **Generate & compare** with the defaults. ARF fits only the training split. The second generator independently samples each training column.
4. In **Generate**, inspect the out-of-bag discriminator accuracy curve and the generated rows. The curve describes the training process, not a complete evaluation of the final synthetic data.
5. In **Evaluate**, compare the holdout with ARF, independent column sampling, and the real training split. The numerical scatter plots should reveal the relationships that independent sampling loses. Results can vary; the demo should not assume that ARF always wins every metric.
6. Change the seed or leaf size and generate again. Discuss changes rather than searching for one universally best setting.
7. Download generated ARF rows and the comparison table as CSV files.

`Iris` is included as a small real mixed tabular example: four numerical flower measurements and one categorical species column.

**## What the metrics mean**

| Metric | Columns | Definition | Interpretation |
|---|---|---|---|
| KS statistic | Numerical | Maximum absolute difference between empirical CDFs | 0–1, smaller is closer; no test p-value |
| Empirical 1D Wasserstein | Numerical | Integral of absolute empirical-CDF differences | Smaller is closer; original column units |
| Total variation distance | Categorical | Half the sum of absolute category-probability differences | 0–1, smaller is closer |
| Pearson correlation gap | Numerical pairs | Absolute difference between two sample correlations | Smaller is closer; incomplete dependency diagnostic |

Category probabilities use the union of observed labels. Factor level order does not determine the distance. Wasserstein calculations support unequal sample sizes and ties. Scores describe finite samples, so zero does not prove that population distributions are identical.

The metric implementation is readable base R code. It is not presented as a validated comprehensive research package or as newly invented methodology.

**## Evaluation design**

- A stratified approximately 80/20 split is made **before generation**. The first categorical variable provides the strata; small group sizes can make the proportion differ slightly from exactly 80/20.
- The holdout is excluded from ARF training, FORDE fitting, and baseline sampling.
- Every generator is compared with the same holdout.
- Real training vs holdout provides context about ordinary sample differences. Its sample size can differ from the synthetic sample size, so it is not a significance threshold or a formal uncertainty estimate.
- Built-in datasets are complete. The univariate helper separately reports missing and excluded rates, but the generation demo does not accept uploaded or incomplete datasets. A missing-data workflow requires a separate design.
- Numerical correlations are explicitly numerical only. A full mixed-variable dependency framework, multivariate metrics, downstream prediction/inference, and privacy attacks are future work.

There is no combined quality score and no "privacy safe" verdict.

**## Package layout**

| File | Purpose |
|---|---|
| `R/core.R` | Data preparation, ARF calls, metrics, and app launcher |
| `inst/shiny/app.R` | Explore, Generate, and Evaluate interface |
| `run.R` | Start directly from the source folder |
| `tests/metrics.R` | Analytical checks for distances and edge cases |
| `scripts/smoke.R` | ARF generation, reproducibility, and app-loading checks |
| `scripts/server-smoke.R` | Actual Shiny server, plot/table rendering, and setting changes |
| `VALIDATION.md` | Checks actually completed in the preparation environment |

The project also has a minimal package structure. To try the installed launcher after installing the dependencies:

```r
install.packages(".", repos = NULL, type = "source")
arfexplorer::run_demo()
```
**## Checks you can run**

From the source folder, with dependencies installed:

```r
source("tests/metrics.R")
source("scripts/smoke.R")
source("scripts/server-smoke.R")
```

From a terminal, `R CMD build .` and `R CMD check arfexplorer_0.0.1.tar.gz` check the package structure. See `VALIDATION.md` for the preparation environment's actual results; commands printed here are not themselves evidence of execution.

**## Sources**

- [ARF on CRAN](https://CRAN.R-project.org/package=arf)
- [Official ARF vignette](https://cran.r-project.org/web/packages/arf/vignettes/arf.html)
- [Watson et al. (2023), Adversarial Random Forests for Density Estimation and Generative Modeling](https://proceedings.mlr.press/v206/watson23a.html)
- [Shiny examples inside R packages](https://pkgs.rstudio.com/shiny/reference/runExample.html)
- [Kapar et al., epidemiological replication study using ARF](https://arxiv.org/abs/2508.14936)