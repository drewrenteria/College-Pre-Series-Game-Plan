# ESPN's college baseball schedule feed carries no conference flag, so
# conference games are found by comparing the opponent's team id against the
# ids in the conference standings. Matching on school NAME across several
# hundred programmes is what produces phantom records.

fns <- load_report_functions(c("mark_conference_games"))

sched <- data.frame(
  event_id              = c("1", "2", "3", "4"),
  opponent_id           = c("26", "30", "9999", "12"),
  opponent              = c("Saint Mary's Gaels", "Oregon State Beavers",
                            "Cal Poly Mustangs", "Washington Huskies"),
  conference_competition = c(NA, TRUE, NA, NA),
  result                = c("W", "L", "W", "W"),
  stringsAsFactors      = FALSE
)

members <- c("26", "30", "12", "100")   # includes the focal team
marked  <- fns$mark_conference_games(sched, members, "100")

expect("opponents in the standings are conference games",
       marked$conference_game, c(TRUE, TRUE, FALSE, TRUE))

expect("the source is recorded for the Data Quality tab",
       unique(marked$conference_source), "conference membership")

expect("the conference record counts only those games",
       paste0(sum(marked$conference_game & marked$result == "W"), "-",
              sum(marked$conference_game & marked$result == "L")),
       "2-1")

# The focal team's own id must not mark its games as conference games
# against itself.
self_marked <- fns$mark_conference_games(
  data.frame(event_id = "5", opponent_id = "100", opponent = "Us",
             conference_competition = NA, stringsAsFactors = FALSE),
  members, "100"
)
expect("the focal team is removed from its own membership list",
       self_marked$conference_game, FALSE)

# When membership cannot be loaded the report falls back to the ESPN flag
# and says so, rather than silently reporting 0-0.
fallback <- fns$mark_conference_games(sched, character(0), "100")
expect("an empty membership list falls back to the ESPN flag",
       fallback$conference_game, c(FALSE, TRUE, FALSE, FALSE))
expect("and the fallback is labelled",
       unique(fallback$conference_source), "ESPN flag")

# Ids are compared as text. A numeric id column must not break the match.
numeric_ids <- sched
numeric_ids$opponent_id <- as.numeric(numeric_ids$opponent_id)
expect("numeric ids compare the same as character ids",
       fns$mark_conference_games(numeric_ids, members, "100")$conference_game,
       c(TRUE, TRUE, FALSE, TRUE))
