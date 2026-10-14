# Play-by-play text is matched to the box-score roster by the name at the
# START of the sentence. An earlier version searched the whole sentence,
# which credited the fielders in "caught stealing second, c Jones to ss
# Lopez" with the steal attempt. These tests hold that line.

fns <- load_report_functions(c("norm_person_key", "initial_last_key",
                               "last_name_key", "build_name_lookups",
                               "match_leading_player"))

initial_last_key     <- fns$initial_last_key
last_name_key        <- fns$last_name_key
norm_person_key      <- fns$norm_person_key
match_leading_player <- fns$match_leading_player

# -- keys ----------------------------------------------------------------

expect("a full name and an initialled name share an initial-last key",
       initial_last_key("Roch Cholowsky"), initial_last_key("R. Cholowsky"))

expect("the initial-last key is first initial plus surname",
       initial_last_key("Roch Cholowsky"), "r_cholowsky")

expect("a lone token has no initial-last key",
       initial_last_key("Cholowsky"), NA_character_)

expect("a suffix is not taken for the surname",
       last_name_key("Ken Griffey Jr."), "griffey")

expect("the surname key ignores a middle initial",
       last_name_key("Ethan P Hawk"), "hawk")

# -- lookups -------------------------------------------------------------

roster <- data.frame(
  athlete_id = c("1", "2", "3"),
  Player     = c("Roch Cholowsky", "Ethan Hawk", "Dean West"),
  stringsAsFactors = FALSE
)
roster$key <- norm_person_key(roster$Player)
lk <- fns$build_name_lookups(roster)

expect("a full name matches",
       match_leading_player("Roch Cholowsky singled to right", lk), "1")

expect("an initialled name matches",
       match_leading_player("R. Cholowsky homered to left", lk), "1")

expect("a bare surname matches when it is unique",
       match_leading_player("Cholowsky grounded out to short", lk), "1")

expect("an unknown leading name matches nobody",
       match_leading_player("Smith walked", lk), NA_character_)

# The whole point of anchoring on the leading name: the fielders named
# later in the sentence must not be credited with the event.
expect("fielders in the tail of the sentence are not credited",
       match_leading_player(
         "Dean West caught stealing second, c Hawk to ss Cholowsky", lk),
       "3")

# -- ambiguity -----------------------------------------------------------

# Two Hawks. A bare "Hawk" is now a guess, so the parser must decline it,
# but the initialled and full forms still resolve.
two_hawks <- data.frame(
  athlete_id = c("1", "2", "3"),
  Player     = c("Roch Cholowsky", "Ethan Hawk", "Brady Hawk"),
  stringsAsFactors = FALSE
)
two_hawks$key <- norm_person_key(two_hawks$Player)
lk2 <- fns$build_name_lookups(two_hawks)

expect("an ambiguous surname is refused rather than guessed",
       match_leading_player("Hawk doubled to left", lk2), NA_character_)

expect("the full name still resolves when the surname is ambiguous",
       match_leading_player("Ethan Hawk doubled to left", lk2), "2")

expect("the initialled name still resolves when the surname is ambiguous",
       match_leading_player("B. Hawk doubled to left", lk2), "3")

expect("an unambiguous surname on the same roster still matches",
       match_leading_player("Cholowsky singled", lk2), "1")

# -- vectorisation -------------------------------------------------------

expect("the matcher is vectorised over a column of play text",
       match_leading_player(
         c("Roch Cholowsky singled", "Hawk doubled", "Smith walked"), lk2),
       c("1", NA_character_, NA_character_))

expect("an empty roster yields no matches",
       match_leading_player("Cholowsky singled",
                            fns$build_name_lookups(roster[0, ])),
       NA_character_)
