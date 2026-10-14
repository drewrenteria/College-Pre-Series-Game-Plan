# Tests

```
Rscript tests/run-all.R        # from the repo root
```

97 assertions. They need R and `dplyr`, `stringr`, `tidyr`, `tibble` and
`janitor`, all of which the report already requires. Nothing here touches the
network, the cache, or `baseballr`.

## How they reach the code

The report is one `.Rmd` on purpose, so there is no package to load. Each test
file calls `load_report_functions()`, which reads
`opponent_advance_report.Rmd`, slices out the named function definitions and
evaluates only those. The report itself never runs, so a test run cannot pull
data or write to `cache/`.

The trade-off is that the extractor matches on `name <- function` at the start
of a line and takes everything up to the next `}` in column one. That is how
the file is written, and a test fails loudly if a name stops resolving.

## What each file covers

| File | What it holds down |
| --- | --- |
| `test-innings.R` | Innings are base-3. 4.2 plus 0.1 is 5.0, and an ERA denominator uses 4.667, not 4.2. |
| `test-identity.R` | One player is one row. Middle initials merge, `A. J. Vukovich` survives, the same name on two teams stays two players. |
| `test-names.R` | Play text is matched on the name that starts the sentence, so the fielders in "c Hawk to ss Cholowsky" are not credited. An ambiguous surname is refused rather than guessed. |
| `test-ledger.R` | Runs per inning survive duplicated rows, shuffled rows and missing pitch rows. |
| `test-conference.R` | Conference games are matched by team id, never by school name. |
| `test-display.R` | A missing number prints as a dash, and a column that is entirely empty is dropped rather than printed as a wall of NA. |

## Two notes worth reading

**Accent folding is locale-dependent.** The report folds accents with
`iconv(..., "ASCII//TRANSLIT")`. In a UTF-8 locale "José" becomes "Jose"; in a
bare `C` locale the accented characters are dropped instead, so an accented
spelling would not join to an unaccented one and the player would appear
twice. RStudio runs in a UTF-8 locale, so this bites headless runs rather than
normal use. `run-all.R` sets a UTF-8 locale explicitly and the test skips
itself, loudly, if none is available.

**The run ledger has one real limit.** It reads the highest score reached in
each inning, so it survives duplicated and missing rows, but not the loss of
the single row holding an inning's top score. `test-ledger.R` asserts that
failure rather than hiding it, which is why the Data Quality tab reconciles
the rebuilt total against the final score instead of trusting it.
