# Tests

```
Rscript tests/run-all.R
```

Run it from the repo root. It needs R, `dplyr`, `stringr`, `tidyr`, `tibble`
and `janitor`, all of which the report itself already uses. There is no test
framework to install.

The report is one `.Rmd` by design, so there is no package to load. Instead
`extract.R` reads the source, slices out individual function definitions by
name, and evaluates only those. Nothing in the suite touches the network, the
cache, or the ESPN and NCAA feeds, so it runs offline in about a second.

## What is covered, and why those things

| File | What it protects |
| --- | --- |
| `test-innings.R` | Innings are base-3. 4.2 is four innings and two outs, so every innings figure is carried as outs. Getting this wrong inflates ERA by about 1%. |
| `test-identity.R` | ESPN sends the same player under several spellings and sometimes several athlete ids. Left alone they become two players, each holding half a season. |
| `test-names.R` | Play attribution comes from the leading name in the play text. An earlier version searched the whole sentence and credited fielders with stolen base attempts. |
| `test-ledger.R` | Scoring by inning is reconstructed from the running scoreboard, not summed from a per-play field. The feed is pitch-level, so summing double counts. |
| `test-conference.R` | Conference games are matched on team id. Matching school names across several hundred programmes is what produces phantom records. |
| `test-display.R` | A report running on partial data should look degraded, not broken. Empty columns are dropped and missing values render as a dash. |

Most of these exist because the behaviour they describe was wrong at some
point during the build. The ledger tests in particular pin down three
properties that a naive implementation fails: the answer must not change when
rows are reordered, must not change when duplicate rows are present, and must
not lose a run when a row is dropped.

## A note on locale

The report folds accented names with `iconv(..., "ASCII//TRANSLIT")`, whose
behaviour depends on the session's character locale. Under `LC_CTYPE=C`,
"José" loses its accented characters rather than becoming "Jose", which would
stop an accented spelling joining to an unaccented one. RStudio runs in a
UTF-8 locale so this does not bite in normal use, but `run-all.R` sets one
explicitly so a headless run tests defined behaviour.
