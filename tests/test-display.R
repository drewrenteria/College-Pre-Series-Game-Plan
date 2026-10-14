# A degraded report should look degraded, not broken. These cover the
# formatters that decide what an unavailable number looks like, and the
# rule that drops a column nothing filled in.

fns <- load_report_functions(c("as_num", "fmt_int", "fmt_chr", "fmt_avg",
                               "drop_empty_cols", "rank_pct"))

fmt_int <- fns$fmt_int
fmt_chr <- fns$fmt_chr

expect("integers print without decimals",
       fmt_int(c(1, 2.4, 2.6)), c("1", "2", "3"))

expect("a missing integer prints as a dash, not NA",
       fmt_int(NA), "—")

expect("an infinite value prints as a dash",
       fmt_int(c(Inf, -Inf)), c("—", "—"))

expect("the blank character is configurable",
       fmt_int(NA, blank = ""), "")

expect("a missing string prints as a dash",
       fmt_chr(NA), "—")

# The specific bug this guards: a character column holding the literal
# text "NA" rendered as the word NA in the table.
expect("the literal string NA prints as a dash",
       fmt_chr("NA"), "—")

expect("an empty string prints as a dash",
       fmt_chr(""), "—")

expect("a real value passes through",
       fmt_chr("Jr."), "Jr.")

expect("a batting average drops the leading zero",
       fns$fmt_avg(0.320), ".320")

expect("a missing average prints as a dash",
       fns$fmt_avg(NA), "—")

# -- empty columns -------------------------------------------------------

# Yr, G, PA, HR and SB only exist when the NCAA feed loaded. Without it the
# report used to print a wall of dashes.
df <- data.frame(
  Player = c("Hawk", "West"),
  AVG    = c(".320", ".288"),
  Yr     = c(NA_character_, NA_character_),
  PA     = c("—", "—"),
  HR     = c("4", "—"),
  stringsAsFactors = FALSE
)
kept <- fns$drop_empty_cols(df)

expect("an all-NA column is dropped",
       "Yr" %in% names(kept), FALSE)

expect("an all-dash column is dropped",
       "PA" %in% names(kept), FALSE)

expect("a partly filled column is kept",
       "HR" %in% names(kept), TRUE)

expect("populated columns survive",
       names(kept), c("Player", "AVG", "HR"))

expect("a named column is kept even when empty",
       "Yr" %in% names(fns$drop_empty_cols(df, keep = "Yr")), TRUE)

expect("a frame with no columns is returned unchanged",
       ncol(fns$drop_empty_cols(df[, 0])), 0L)

# -- percentiles ---------------------------------------------------------

expect("percentiles run from 0 to 1",
       fns$rank_pct(c(1, 2, 3, 4)), c(0, 1/3, 2/3, 1))

expect("a single value is the top of its own scale",
       fns$rank_pct(5), 1)

expect("NA does not shift the scale",
       fns$rank_pct(c(1, NA, 3)), c(0, NA, 1))

expect("an all-NA column yields all NA",
       fns$rank_pct(c(NA_real_, NA_real_)), c(NA_real_, NA_real_))

expect("ties share a percentile",
       fns$rank_pct(c(1, 1, 3)), c(0.25, 0.25, 1))
