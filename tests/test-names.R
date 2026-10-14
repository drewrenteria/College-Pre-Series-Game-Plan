# Play-by-play text is free prose. The original parser searched the whole
# sentence for any roster name, so "Rivera caught stealing second, c Jones
# to ss Lopez" credited Jones and Lopez with steal attempts. Attribution is
# now taken from the LEADING name only, and a bare surname is used only when
# it is unique across both rosters.

fns <- load_report_functions(c("norm_person_key", "initial_last_key",
                               "last_name_key", "build_name_lookups",
                               "match_leading_player"))

initial_last_key <- fns$initial_last_key
last_name_key    <- fns$last_name_key
norm_person_key  <- fns$norm_person_key

expect("an initial and a full first name share a key",
       initial_last_key("R. Cholowsky"), initial_last_key("Roch Cholowsky"))

expect("the key is first initial and surname",
       initial_last_key("Roch Cholowsky"), "r_cholowsky")

expect("a suffix does not become the surname",
       initial_last_key("Ken Griffey Jr."), "k_griffey")

expect("a lone surname has no initial key",
       initial_last_key("Cholowsky"), NA_character_)

expect("the surname key is the surname",
       last_name_key("Roch Cholowsky"), "cholowsky")

expect("a lone initial is not mistaken for a surname",
       last_name_key("R. Cholowsky"), "cholowsky")

# Two Hawks. Every surname-only reference to either is now unresolvable,
# which is the correct answer.
roster <- data.frame(
  athlete_id = c("1", "2", "3", "4"),
  Player     = c("Roch Cholowsky", "Ethan Hawk", "Easton Hawk", "Dean West"),
  stringsAsFactors = FALSE
)
roster$key <- norm_person_key(roster$Player)
lk <- fns$build_name_lookups(roster)

m <- function(txt) fns$match_leading_player(txt, lk)

expect("a full name matches",
       m("Roch Cholowsky doubled to left"), "1")

expect("an initialled name matches",
       m("R. Cholowsky homered to right"), "1")

expect("a unique surname matches",
       m("Cholowsky singled to center"), "1")

expect("a duplicated surname is refused, not guessed",
       m("Hawk grounded out to short"), NA_character_)

expect("a duplicated initial-and-surname is also refused",
       m("E. Hawk flied out to left"), NA_character_)

expect("a full name disambiguates the two Hawks",
       m("Ethan Hawk walked"), "2")

expect("the other Hawk resolves too",
       m("Easton Hawk struck out swinging"), "3")

# The regression that started all of this. Only the runner is credited.
expect("fielders named later in the sentence are not credited",
       m("Dean West caught stealing second, c Cholowsky to ss Hawk"), "4")

expect("a surname leading the sentence beats one inside it",
       m("West singled to right, Cholowsky to third"), "4")

expect("an unknown name yields NA",
       m("Smith doubled to the gap"), NA_character_)

expect("leading punctuation does not block the match",
       m("  - Cholowsky singled"), "1")

expect("an empty roster matches nothing",
       fns$match_leading_player("Cholowsky singled",
                                fns$build_name_lookups(roster[0, ])),
       NA_character_)

expect("the matcher is vectorised over a column of play text",
       m(c("Cholowsky singled", "Hawk grounded out", "Dean West walked")),
       c("1", NA_character_, "4"))
