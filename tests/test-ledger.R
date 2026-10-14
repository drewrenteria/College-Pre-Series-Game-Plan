# Scoring by inning is reconstructed from the running scoreboard rather than
# summed out of a per-play "scoreValue" field. The feed is pitch-level: the
# same score appears on many rows, and the result row repeats it again, so
# summing double-counts. Taking the highest score reached in each inning and
# differencing makes the answer immune to row order and to dropped rows.

fns <- load_report_functions(c("as_num", "pick_col", "col_or_na",
                               "build_run_ledger"))

sched <- data.frame(event_id = "G1", home_away = "home",
                    stringsAsFactors = FALSE)

# Home (the focal team) scores 2 in the first, away scores 1 in the second,
# nobody scores in the third. Several rows per inning, as the feed sends it.
plays <- data.frame(
  game_id       = rep("G1", 9),
  period_number = c(1, 1, 1, 1, 2, 2, 2, 3, 3),
  away_score    = c(0, 0, 0, 0, 0, 1, 1, 1, 1),
  home_score    = c(0, 0, 2, 2, 2, 2, 2, 2, 2),
  stringsAsFactors = FALSE
)

led <- fns$build_run_ledger(plays, "100", sched)

expect("one row per inning, not per play", nrow(led), 3L)

expect("the focal team's runs land in the right inning",
       led$FocalRuns, c(2, 0, 0))

expect("the opponent's runs land in the right inning",
       led$OppRuns, c(0, 1, 0))

expect("repeated rows do not double count the focal team",
       sum(led$FocalRuns), 2)

expect("repeated rows do not double count the opponent",
       sum(led$OppRuns), 1)

# Order independence: the same rows shuffled must produce the same ledger.
set.seed(42)
shuffled <- plays[sample(nrow(plays)), ]
led_shuffled <- fns$build_run_ledger(shuffled, "100", sched)
expect("shuffling the rows changes nothing",
       led_shuffled$FocalRuns, led$FocalRuns)

# Dropped rows: the feed sometimes omits the row that "carried" a run. The
# max-per-inning approach still recovers it, which summing a per-play field
# would not.
thinned <- plays[-c(3, 6), ]
led_thinned <- fns$build_run_ledger(thinned, "100", sched)
expect("dropping the row that scored still recovers the run",
       sum(led_thinned$FocalRuns), 2)

# Away team as the focal team: the same scoreboard, read from the other side.
sched_away <- data.frame(event_id = "G1", home_away = "away",
                         stringsAsFactors = FALSE)
led_away <- fns$build_run_ledger(plays, "100", sched_away)
expect("the home/away assignment flips the columns",
       led_away$FocalRuns, c(0, 1, 0))
expect("and flips the opponent column too",
       led_away$OppRuns, c(2, 0, 0))

# A mid-inning correction that reads LOW must not produce a negative run.
corrected <- data.frame(
  game_id       = rep("G1", 4),
  period_number = c(1, 1, 2, 2),
  away_score    = c(0, 0, 0, 0),
  home_score    = c(3, 1, 3, 3),     # 3 then a correction down to 1
  stringsAsFactors = FALSE
)
led_corrected <- fns$build_run_ledger(corrected, "100", sched)
expect("a backwards correction never yields negative runs",
       any(led_corrected$FocalRuns < 0), FALSE)
expect("the high-water mark is kept",
       sum(led_corrected$FocalRuns), 3)

# Innings arrive out of order in some feeds. They are sorted explicitly.
jumbled <- plays[order(-plays$period_number), ]
led_jumbled <- fns$build_run_ledger(jumbled, "100", sched)
expect("innings are sorted before differencing",
       led_jumbled$Inning, c(1, 2, 3))
expect("and the runs still land correctly",
       led_jumbled$FocalRuns, c(2, 0, 0))

# Degenerate input
expect("an empty frame yields an empty ledger",
       nrow(fns$build_run_ledger(plays[0, ], "100", sched)), 0L)

expect("a frame missing the score columns yields an empty ledger",
       nrow(fns$build_run_ledger(data.frame(game_id = "G1"), "100", sched)), 0L)

expect("pre-game rows with no inning are dropped",
       nrow(fns$build_run_ledger(
         data.frame(game_id = "G1", period_number = NA_real_,
                    away_score = 0, home_score = 0), "100", sched)), 0L)
