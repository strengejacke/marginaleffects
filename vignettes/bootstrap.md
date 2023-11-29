
# Bootstrap & Simulation

`marginaleffects` offers an `inferences()` function to compute
uncertainty estimates using the bootstrap and simulation-based
inference.

WARNING: The `inferences()` function is experimental. It may be renamed,
the user interface may change, or the functionality may migrate to
arguments in other `marginaleffects` functions.

Consider a simple model:

``` r
library(marginaleffects)

mod <- lm(Sepal.Length ~ Petal.Width * Petal.Length + factor(Species), data = iris)
```

We will compute uncertainty estimates around the output of
`comparisons()`, but note that the same approach works with the
`predictions()` and `slopes()` functions as well.

## Delta method

The default strategy to compute standard errors and confidence intervals
is the delta method. This is what we obtain by calling:

``` r
avg_comparisons(mod, by = "Species", variables = "Petal.Width")
#> 
#>         Term Contrast    Species Estimate Std. Error      z Pr(>|z|)   S  2.5 % 97.5 %
#>  Petal.Width mean(+1) setosa      -0.1103      0.285 -0.387    0.699 0.5 -0.669  0.449
#>  Petal.Width mean(+1) versicolor  -0.0201      0.160 -0.125    0.900 0.2 -0.334  0.293
#>  Petal.Width mean(+1) virginica    0.0216      0.169  0.128    0.898 0.2 -0.309  0.353
#> 
#> Columns: term, contrast, Species, estimate, std.error, statistic, p.value, s.value, conf.low, conf.high, predicted_lo, predicted_hi, predicted 
#> Type:  response
```

Since this is the default method, we obtain the same results if we add
the `inferences()` call in the chain:

``` r
avg_comparisons(mod, by = "Species", variables = "Petal.Width") |>
  inferences(method = "delta")
#> 
#>         Term Contrast    Species Estimate Std. Error      z Pr(>|z|)   S  2.5 % 97.5 %
#>  Petal.Width mean(+1) setosa      -0.1103      0.285 -0.387    0.699 0.5 -0.669  0.449
#>  Petal.Width mean(+1) versicolor  -0.0201      0.160 -0.125    0.900 0.2 -0.334  0.293
#>  Petal.Width mean(+1) virginica    0.0216      0.169  0.128    0.898 0.2 -0.309  0.353
#> 
#> Columns: term, contrast, Species, estimate, std.error, statistic, p.value, s.value, conf.low, conf.high, predicted_lo, predicted_hi, predicted 
#> Type:  response
```

## Bootstrap

`marginaleffects` supports three bootstrap frameworks in `R`: the
well-established `boot` package, the newer `rsample` package, and the
so-called “bayesian bootstrap” in `fwb`.

### `boot`

``` r
avg_comparisons(mod, by = "Species", variables = "Petal.Width") |>
  inferences(method = "boot")
#> 
#>         Term Contrast    Species Estimate Std. Error  2.5 % 97.5 %
#>  Petal.Width mean(+1) setosa      -0.1103      0.271 -0.606  0.442
#>  Petal.Width mean(+1) versicolor  -0.0201      0.167 -0.334  0.299
#>  Petal.Width mean(+1) virginica    0.0216      0.187 -0.343  0.368
#> 
#> Columns: term, contrast, Species, estimate, predicted_lo, predicted_hi, predicted, std.error, conf.low, conf.high 
#> Type:  response
```

All unknown arguments that we feed to `inferences()` are pushed forward
to `boot::boot()`:

``` r
est <- avg_comparisons(mod, by = "Species", variables = "Petal.Width") |>
  inferences(method = "boot", sim = "balanced", R = 500, conf_type = "bca")
est
#> 
#>         Term Contrast    Species Estimate Std. Error  2.5 % 97.5 %
#>  Petal.Width mean(+1) setosa      -0.1103      0.269 -0.688  0.396
#>  Petal.Width mean(+1) versicolor  -0.0201      0.158 -0.316  0.299
#>  Petal.Width mean(+1) virginica    0.0216      0.182 -0.335  0.393
#> 
#> Columns: term, contrast, Species, estimate, predicted_lo, predicted_hi, predicted, std.error, conf.low, conf.high 
#> Type:  response
```

We can extract the original `boot` object from an attribute:

``` r
attr(est, "inferences")
#> 
#> BALANCED BOOTSTRAP
#> 
#> 
#> Call:
#> bootstrap_boot(model = model, INF_FUN = INF_FUN, newdata = ..1, 
#>     vcov = ..2, variables = ..3, type = ..4, by = ..5, conf_level = ..6, 
#>     cross = ..7, comparison = ..8, transform = ..9, wts = ..10, 
#>     hypothesis = ..11, eps = ..12)
#> 
#> 
#> Bootstrap Statistics :
#>        original      bias    std. error
#> t1* -0.11025325 0.010638159   0.2687425
#> t2* -0.02006005 0.004258223   0.1576333
#> t3*  0.02158742 0.001312235   0.1824467
```

Or we can extract the individual draws with the `posterior_draws()`
function:

``` r
posterior_draws(est) |> head()
#>   drawid       draw        term contrast    Species    estimate predicted_lo predicted_hi predicted std.error   conf.low conf.high
#> 1      1 -0.2997203 Petal.Width mean(+1)     setosa -0.11025325     4.957514     4.845263  4.957514 0.2687425 -0.6875060 0.3956670
#> 2      1 -0.1804525 Petal.Width mean(+1) versicolor -0.02006005     6.327949     6.322072  6.327949 0.1576333 -0.3162988 0.2985886
#> 3      1 -0.1253796 Petal.Width mean(+1)  virginica  0.02158742     7.015513     7.051542  7.015513 0.1824467 -0.3353508 0.3933245
#> 4      2 -0.2651303 Petal.Width mean(+1)     setosa -0.11025325     4.957514     4.845263  4.957514 0.2687425 -0.6875060 0.3956670
#> 5      2 -0.2034462 Petal.Width mean(+1) versicolor -0.02006005     6.327949     6.322072  6.327949 0.1576333 -0.3162988 0.2985886
#> 6      2 -0.1749630 Petal.Width mean(+1)  virginica  0.02158742     7.015513     7.051542  7.015513 0.1824467 -0.3353508 0.3933245

posterior_draws(est, shape = "DxP") |> dim()
#> [1] 500   3
```

### `rsample`

As before, we can pass arguments to `rsample::bootstraps()` through
`inferences()`. For example, for stratified resampling:

``` r
est <- avg_comparisons(mod, by = "Species", variables = "Petal.Width") |>
  inferences(method = "rsample", R = 100, strata = "Species")
est
#> 
#>         Term Contrast    Species Estimate  2.5 % 97.5 %
#>  Petal.Width mean(+1) setosa      -0.1103 -0.639  0.264
#>  Petal.Width mean(+1) versicolor  -0.0201 -0.311  0.311
#>  Petal.Width mean(+1) virginica    0.0216 -0.308  0.358
#> 
#> Columns: term, contrast, Species, estimate, predicted_lo, predicted_hi, predicted, conf.low, conf.high 
#> Type:  response

attr(est, "inferences")
#> # Bootstrap sampling using stratification with apparent sample 
#> # A tibble: 101 × 3
#>    splits           id           estimates       
#>    <list>           <chr>        <list>          
#>  1 <split [150/50]> Bootstrap001 <tibble [3 × 7]>
#>  2 <split [150/55]> Bootstrap002 <tibble [3 × 7]>
#>  3 <split [150/55]> Bootstrap003 <tibble [3 × 7]>
#>  4 <split [150/60]> Bootstrap004 <tibble [3 × 7]>
#>  5 <split [150/52]> Bootstrap005 <tibble [3 × 7]>
#>  6 <split [150/52]> Bootstrap006 <tibble [3 × 7]>
#>  7 <split [150/54]> Bootstrap007 <tibble [3 × 7]>
#>  8 <split [150/59]> Bootstrap008 <tibble [3 × 7]>
#>  9 <split [150/61]> Bootstrap009 <tibble [3 × 7]>
#> 10 <split [150/53]> Bootstrap010 <tibble [3 × 7]>
#> # ℹ 91 more rows
```

Or we can extract the individual draws with the `posterior_draws()`
function:

``` r
posterior_draws(est) |> head()
#>   drawid         draw        term contrast    Species    estimate predicted_lo predicted_hi predicted   conf.low conf.high
#> 1      1 -0.018347483 Petal.Width mean(+1)     setosa -0.11025325     4.957514     4.845263  4.957514 -0.6393702 0.2639397
#> 2      1  0.009371202 Petal.Width mean(+1) versicolor -0.02006005     6.327949     6.322072  6.327949 -0.3108048 0.3108965
#> 3      1  0.022170537 Petal.Width mean(+1)  virginica  0.02158742     7.015513     7.051542  7.015513 -0.3079096 0.3581024
#> 4      2 -0.681668871 Petal.Width mean(+1)     setosa -0.11025325     4.957514     4.845263  4.957514 -0.6393702 0.2639397
#> 5      2 -0.522346181 Petal.Width mean(+1) versicolor -0.02006005     6.327949     6.322072  6.327949 -0.3108048 0.3108965
#> 6      2 -0.448777591 Petal.Width mean(+1)  virginica  0.02158742     7.015513     7.051542  7.015513 -0.3079096 0.3581024

posterior_draws(est, shape = "PxD") |> dim()
#> [1]   3 100
```

### Fractional Weighted Bootstrap (aka Bayesian Bootstrap)

[The `fwb` package](https://ngreifer.github.io/fwb/) implements
fractional weighted bootstrap (aka Bayesian bootstrap):

> “fwb implements the fractional weighted bootstrap (FWB), also known as
> the Bayesian bootstrap, following the treatment by Xu et al. (2020).
> The FWB involves generating sets of weights from a uniform Dirichlet
> distribution to be used in estimating statistics of interest, which
> yields a posterior distribution that can be interpreted in the same
> way the traditional (resampling-based) bootstrap distribution can be.”
> -Noah Greifer

The `inferences()` function makes it easy to apply this inference
strategy to `marginaleffects` objects:

``` r
avg_comparisons(mod) |> inferences(method = "fwb")
#> 
#>          Term            Contrast Estimate Std. Error  2.5 % 97.5 %
#>  Petal.Length +1                    0.8929      0.079  0.726  1.047
#>  Petal.Width  +1                   -0.0362      0.159 -0.329  0.302
#>  Species      versicolor - setosa  -1.4629      0.324 -2.141 -0.841
#>  Species      virginica - setosa   -1.9842      0.384 -2.730 -1.252
#> 
#> Columns: term, contrast, estimate, std.error, conf.low, conf.high 
#> Type:  response
```

## Simulation-based inference

This simulation-based strategy to compute confidence intervals was
described in Krinsky & Robb (1986) and popularized by King, Tomz,
Wittenberg (2000). We proceed in 3 steps:

1.  Draw `R` sets of simulated coefficients from a multivariate normal
    distribution with mean equal to the original model’s estimated
    coefficients and variance equal to the model’s variance-covariance
    matrix (classical, “HC3”, or other).
2.  Use the `R` sets of coefficients to compute `R` sets of estimands:
    predictions, comparisons, or slopes.
3.  Take quantiles of the resulting distribution of estimands to obtain
    a confidence interval and the standard deviation of simulated
    estimates to estimate the standard error.

Here are a few examples:

``` r
library(ggplot2)
library(ggdist)

avg_comparisons(mod, by = "Species", variables = "Petal.Width") |>
  inferences(method = "simulation")
#> 
#>         Term Contrast    Species Estimate Std. Error  2.5 % 97.5 %
#>  Petal.Width mean(+1) setosa      -0.1103      0.275 -0.685  0.398
#>  Petal.Width mean(+1) versicolor  -0.0201      0.159 -0.348  0.283
#>  Petal.Width mean(+1) virginica    0.0216      0.171 -0.307  0.355
#> 
#> Columns: term, contrast, Species, estimate, std.error, conf.low, conf.high, predicted_lo, predicted_hi, predicted, tmp_idx 
#> Type:  response
```

Since simulation based inference generates `R` estimates of the
quantities of interest, we can treat them similarly to draws from the
posterior distribution in bayesian models. For example, we can extract
draws using the `posterior_draws()` function, and plot their
distributions using packages like`ggplot2` and `ggdist`:

``` r
avg_comparisons(mod, by = "Species", variables = "Petal.Width") |>
  inferences(method = "simulation") |>
  posterior_draws("rvar") |>
  ggplot(aes(y = Species, xdist = rvar)) +
  stat_slabinterval()
```

<img
src="../bootstrap.markdown_strict_files/figure-markdown_strict/unnamed-chunk-13-1.png"
style="width:100.0%" />

## Multiple imputation and missing data

The same workflow and the same `inferences` function can be used to
estimate models with multiple imputation for missing data.
