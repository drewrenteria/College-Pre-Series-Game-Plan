# ESPN sends the same player under more than one spelling, and sometimes
# under more than one athlete id. Left alone they become two players, each
# holding half a season. These tests cover the merge.

fns <- load_report_functions(c("tidy_display_name", "norm_person_key",
                               "build_identity_map", "apply_identity"))

tidy_display_name <- fns$tidy_display_name
norm_person_key   <- fns$norm_person_key

# -- tidying -------------------------------------------------------------

expect("a middle initial is dropped",
       tidy_display_name("Ethan P Hawk"), "Ethan Hawk")

expect("a punctuated middle initial is dropped",
       tidy_display_name("Ethan P. Hawk"), "Ethan Hawk")

expect("a two-token name is left alone",
       tidy_display_name("Ethan Hawk"), "Ethan Hawk")

# The report shows the player's name, so initials that ARE the name have to
# survive. This is the case the naive "drop single letters" rule gets wrong.
expect("a leading double initial survives",
       tidy_display_name("A. J. Vukovich"), "A. J. Vukovich")

expect("a dotted first name survives",
       tidy_display_name("J.T. Realmuto"), "J.T. Realmuto")

expect("a suffix is not mistaken for a middle initial",
       tidy_display_name("Ken Griffey Jr."), "Ken Griffey Jr.")

expect("empty input stays NA",
       tidy_display_name(c(NA, "")), c(NA_character_, NA_character_))

# -- keys ----------------------------------------------------------------

expect("the key ignores word order",
       norm_person_key("Hawk, Ethan"), norm_person_key("Ethan Hawk"))

expect("the key ignores a middle initial",
       norm_person_key("Ethan P Hawk"), norm_person_key("Ethan Hawk"))

expect("the key ignores a generational suffix",
       norm_person_key("Ken Griffey Jr."), norm_person_key("Ken Griffey"))

expect("the key folds accents",
       norm_person_key("José Ramírez"), norm_person_key("Jose Ramirez"))

expect("different players get different keys",
       norm_person_key("Ethan Hawk") != norm_person_key("Evan Hawk"), TRUE)

# -- the map -------------------------------------------------------------

# Three box scores spell him plainly, one adds the initial. Same id.
roster <- data.frame(
  athlete_id           = c("1", "1", "1", "1", "2"),
  athlete_display_name = c("Ethan Hawk", "Ethan Hawk", "Ethan Hawk",
                           "Ethan P Hawk", "Roch Cholowsky"),
  team_id              = rep("100", 5),
  stringsAsFactors     = FALSE
)
map <- fns$build_identity_map(roster)

expect("one row per incoming athlete id", nrow(map), 2L)

hawk <- map[map$athlete_id == "1", ]
expect("the most-used spelling wins", hawk$Player, "Ethan Hawk")
expect("the name variance is reported on raw spellings",
       hawk$name_variants, 2L)
expect("a single id reports no id variance", hawk$id_variants, 1L)

# Same human, two ids. The id carrying more rows becomes canonical.
split_ids <- data.frame(
  athlete_id           = c("7", "7", "7", "9"),
  athlete_display_name = c("Ethan Hawk", "Ethan Hawk", "Ethan Hawk",
                           "Ethan P Hawk"),
  team_id              = rep("100", 4),
  stringsAsFactors     = FALSE
)
map2 <- fns$build_identity_map(split_ids)
expect("both ids map to the busier one",
       sort(unique(map2$canonical_id)), "7")
expect("the id variance is reported",
       unique(map2$id_variants), 2L)

# A name collision across two teams must NOT merge.
two_teams <- data.frame(
  athlete_id           = c("11", "22"),
  athlete_display_name = c("Chris Smith", "Chris Smith"),
  team_id              = c("100", "200"),
  stringsAsFactors     = FALSE
)
map3 <- fns$build_identity_map(two_teams)
expect("same name on two teams stays two players",
       length(unique(map3$canonical_id)), 2L)

expect("an empty frame yields an empty map",
       nrow(fns$build_identity_map(roster[0, ])), 0L)

# -- applying it ---------------------------------------------------------

stats <- data.frame(
  athlete_id = c("7", "9"),
  Player     = c("Ethan Hawk", "Ethan P Hawk"),
  AB         = c(40, 12),
  stringsAsFactors = FALSE
)
applied <- fns$apply_identity(stats, map2)

expect("both rows now carry one id",
       unique(applied$athlete_id), "7")
expect("both rows now carry one name",
       unique(applied$Player), "Ethan Hawk")
expect("at-bats are untouched by the remap",
       sum(applied$AB), 52)
expect("no join columns leak into the result",
       any(grepl("^\\.canon", names(applied))), FALSE)
