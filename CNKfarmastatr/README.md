# CNKfarmastatr

Statistical core of **CNK-FarmaStatR**, a reproducible, simulation-oriented platform for pharmaceutical statistics in education and research.

> For research and education only. Not a validated system for GxP environments.
> Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.

Development version 1.0.0.9000. Version 1.0.0 will be released together with the platform paper.

## Models (validated once, per model)

| Model | Reference | Checks |
|---|---|---|
| Model-independent MSD (Mahalanobis, Hotelling T²) | FDA 1997 V.B; Tsong et al. 1996 | 60 |
| Weibull model-dependent MSD | FDA 1997 V.C; Sathe et al. 1996 | 98 |
| f2, expected f2, bootstrap f2 (EMA and FDA perspectives, percentile and BCa) | EMA Q&A 3.11; Noce et al. 2020; Xu et al. 2021 | 120 |
| In vitro population bioequivalence | FDA PSG 020929 (Dec 2025) | 213 |

## Run the validation tests

```r
# from the package folder
testthat::test_local()
```
