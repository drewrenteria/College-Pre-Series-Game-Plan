# A degraded report should look degraded, not broken. These cover the
# formatting rules that keep an empty cell from printing as the string "NA".

fns <- load_report_functions(c("as_num", "fmt_int", "fmt_chr",
                               "drop_empty_cols", "fmt_avg", "rank_pct"))
fmt_int <- fns$fmt_int; fmt_chr <- fns$fmt_chr
drop_empty_cols <- fns$drop_empty_cols

expect("integers print without decimals", fmt_int(c(3, 12.4)), c("3", "12"))
expect("a missing integer prints as a dash", fmt_int(NA), "—")
expect("an infinite integer prints as a dash", fmt_int(Inf), "—")
expect("the blank can be overridden", fmt_int(NA, blank = "n/a"), "n/a")

expect("text passes through", fmt_chr("Jr"), "Jr")
expect("an empty string prints as a dash", fmt_chr(""), "—")
expect("a literal NA string prints as a dash", fmt_chr("NA"), "—")
expect("a missing value prints as a dash", fmt_chr(NA), "—")

expect("a batting average drops the leading zero",
       fns$fmt_avg(0.32), ".320")
expect("a batting average always shows three places",
       fns$fmt_avg(0.3), ".300")
expect("a missing average prints as a dash", fns$fmt_avg(NA), "—")

# -- empty columns -------------------------------------------------------

# Yr, G, PA, HR and SB only exist when the NCAA feed answered. When it did
# not, printing a wall of dashes makes a working report look broken.
df <- data.frame(
  Player = c("Roch Cholowsky", "Dean West"),
  AVG    = c(".320", ".288"),
  Yr     = c("—", "—"),
  PA     = c(NA_character_, NA_character_),
  HR     = c("21", "8"),
  stringsAsFactors = FALSE
)
kept <- drop_empty_cols(df)
expect("a column of dashes is dropped", "Yr" %in% names(kept), FALSE)
expect("a column of NA is dropped",     "PA" %in% names(kept), FALSE)
expect("a populated column is kept",    "HR" %in% names(kept), TRUE)
expect("the identifier column is kept", "Player" %in% names(kept), TRUE)

expect("a named column survives even when empty",
       "Yr" %in% names(drop_empty_cols(df, keep = "Yr")), TRUE)

# With no rows every column counts as empty, so all of them go. Recorded
# because it is the observed behaviour, not because it is load-bearing: the
# report does not render a table that has no rows.
expect("a zero-row frame drops every column",
       ncol(drop_empty_cols(df[0, ])), 0L)

# -- percentiles ---------------------------------------------------------

expect("percentiles span zero to one",
       fns$rank_pct(c(1, 2, 3)), c(0, 0.5, 1))
expect("a lone value is the top of its own scale",
       fns$rank_pct(5), 1)
expect("missing values stay missing",
       fns$rank_pct(c(1, NA, 3)), c(0, NA, 1))
expect("an all-missing vector yields all missing",
       fns$rank_pct(c(NA_real_, NA_real_)), c(NA_real_, NA_real_))
