# CNK-FarmaStatR v1

Reproducible platform for pharmaceutical statistics in education and research
(development version 1.0.0.9000).

For research and education; not a system validated for GxP environments.

Türkçe: [OKUBENI.md](OKUBENI.md)

## Use

Serve the repository root locally (R):

```r
httpuv::runStaticServer(".", port = 8000)
```

| Address | Content |
|---|---|
| `http://127.0.0.1:8000/web/app/` | In vitro PBE simulation and design selection (ℓ × n × m; FDA, EMA) |
| `http://127.0.0.1:8000/web/analiz/` | Analysis of your own data: PBE; f2 and bootstrap f2; model-independent MSD; Weibull MSD |
| `http://127.0.0.1:8000/web/analiz/dogrula.html` | Validation in the browser (516 inherited checks, package tests) |
| `http://127.0.0.1:8000/web/yardim/yontem/?lang=en` | Method notes (PBE, f2, MSD, Weibull, simulation) |

All computation runs in R inside the browser (webR); data never leave the browser. Each result is
recorded with its seed, RNG and versions and can be reproduced from a link or an exported R script.

## Layout

- `CNKfarmastatr/` — R package (statistical cores, platform functions, tests)
- `web/` — browser interface; `veri/` — SQLite database of precomputed results
- `simulasyon/` — simulation studies; `belgeler/` — technical notes and validation documents (Turkish)
- `FSR-LOG-01_v1_gunluk.md` — project log (Turkish)

Citation: `CITATION.cff` (draft; license and DOI at release).
