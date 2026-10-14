# Scoring by inning is rebuilt from the running scoreboard on each play row.
# Two earlier versions got this wrong: summing a scoreValue column double
# counted (the value appears on the pitch rows AND on the result row), and
# differencing the score after dropping pitch rows lost any run whose row had
# been dropped. The current version takes the highest score REACHED in each
# inning and differences those, which is immune to row order and to most
# row filtering.

fns <- load_report_functions(c("as_num", "pick_col", "col_or_na",
                               "build_run_ledger"))
build_run_ledger <- fns$build_run_ledger

# UCLA at home. The away team scores 2 in the 1st; UCLA scores 1 in the 2nd
# and 2 in the 3rd. Several rows per inning, because the feed is pitch-level.
plays <- data.frame(
  game_id       = rep("G1", 9),
  period_number = c(1, 1, 1, 2, 2, 2, 3, 3, 3),
  away_score    = c(0, 1, 2, 2, 2, 2, 2, 2, 2),
  home_score    = c(0, 0, 0, 0, 1, 1, 1, 2, 3),
  stringsAsFactors = FALSE
)
sched <- data.frame(event_id = "G1", home_away = "home",
                    stringsAsFactors = FALSE)

led <- build_run_ledger(plays, "66", sched)

expect("one row per inning", nrow(led), 3L)
expect("innings come back in order", led$Inning, c(1, 2, 3))
expect("the home team's runs land on FocalRuns", led$FocalRuns, c(0, 1, 2))
expect("the away team's runs land on OppRuns",   led$OppRuns,   c(2, 0, 0))
expect("the ledger totals the real final score",
       c(sum(led$FocalRuns), sum(led$OppRuns)), c(3, 2))

# -- the properties the earlier versions failed -------------------------

dup <- rbind(plays, plays)
expect("duplicated rows do not double count",
       build_run_ledger(dup, "66", sched)$FocalRuns, c(0, 1, 2))

set.seed(1)
shuffled <- plays[sample(nrow(plays)), ]
expect("row order inside an inning is irrelevant",
       build_run_ledger(shuffled, "66", sched)$FocalRuns, c(0, 1, 2))

# The feed does not always return every pitch row. Dropping an intermediate
# row must not lose a run, because the inning maximum is read rather than a
# row-by-row accumulation. Row 2 is the away team passing through 1 on its
# way to 2 in the first.
expect("dropping an intermediate row does not lose a run",
       build_run_ledger(plays[-2, ], "66", sched)$OppRuns, c(2, 0, 0))

# The one row that cannot go missing is the inning's highest score. That is
# a real limit of the approach, asserted here so it stays understood: it is
# why the Data Quality tab reconciles the rebuilt total against the final
# score rather than trusting it.
expect("losing an inning's top row does lose that run",
       sum(build_run_ledger(plays[-9, ], "66", sched)$FocalRuns), 2)

# A mid-inning correction that reads low must not produce a negative run.
dip <- plays
dip$home_score[6] <- 0
expect("a scoreboard that reads low never yields a negative run",
       any(build_run_ledger(dip, "66", sched)$FocalRuns < 0), FALSE)

# Innings arriving out of order are sorted before differencing.
expect("out-of-order innings are sorted first",
       build_run_ledger(plays[rev(seq_len(nrow(plays))), ],
                        "66", sched)$FocalRuns, c(0, 1, 2))

# -- the other side of the ledger ---------------------------------------

away_sched <- data.frame(event_id = "G1", home_away = "away",
                         stringsAsFactors = FALSE)
expect("playing away swaps the two columns",
       build_run_ledger(plays, "66", away_sched)$FocalRuns, c(2, 0, 0))

# -- more than one game --------------------------------------------------

two <- rbind(
  plays,
  data.frame(game_id = rep("G2", 3), period_number = c(1, 2, 3),
             away_score = c(1, 1, 1), home_score = c(0, 0, 4),
             stringsAsFactors = FALSE)
)
two_sched <- data.frame(event_id = c("G1", "G2"),
                        home_away = c("home", "home"),
                        stringsAsFactors = FALSE)
led2 <- build_run_ledger(two, "66", two_sched)
expect("games are kept separate", nrow(led2), 6L)
expect("the second game starts its own running total",
       led2$FocalRuns[led2$game_id == "G2"], c(0, 0, 4))

# -- degenerate input ----------------------------------------------------

expect("an empty frame yields an empty ledger",
       nrow(build_run_ledger(plays[0, ], "66", sched)), 0L)

expect("a frame with no score columns yields an empty ledger",
       nrow(build_run_ledger(plays[, c("game_id", "period_number")],
                             "66", sched)), 0L)

pregame <- plays
pregame$period_number <- 0
expect("rows before the first inning are ignored",
       nrow(build_run_ledger(pregame, "66", sched)), 0L)
