# Run every test:  Rscript tests/run-all.R   (from the repo root)
#
# The report folds accents with iconv(..., "ASCII//TRANSLIT"), whose
# behaviour depends on the session's character locale. Under LC_CTYPE=C,
# "José" loses its accented characters entirely instead of becoming "Jose",
# which would stop an accented spelling joining to an unaccented one. RStudio
# runs in a UTF-8 locale, so this matters mainly for headless runs; it is set
# explicitly here so the suite tests one defined behaviour.
suppressWarnings({
  for (loc in c("C.UTF-8", "en_US.UTF-8", "English_United States.utf8")) {
    if (!inherits(try(Sys.setlocale("LC_CTYPE", loc), silent = TRUE),
                  "try-error") &&
        grepl("utf-?8", Sys.getlocale("LC_CTYPE"), ignore.case = TRUE)) break
  }
})

source("tests/extract.R")
source("tests/harness.R")

files <- sort(list.files("tests", pattern = "^test-.*\\.R$", full.names = TRUE))
for (f in files) {
  cat("\n", basename(f), "\n", sep = "")
  source(f)
}

report_results()
