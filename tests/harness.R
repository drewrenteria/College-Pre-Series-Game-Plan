# A deliberately small assertion harness. The report depends on R, rmarkdown
# and baseballr; the tests add nothing to that list, so anyone who can knit
# the report can run them.

.results <- new.env(parent = emptyenv())
.results$pass <- 0L
.results$fail <- 0L
.results$skip <- 0L
.results$failures <- character(0)
.results$skips <- character(0)

expect <- function(label, actual, expected) {
  ok <- isTRUE(all.equal(actual, expected))
  if (ok) {
    .results$pass <- .results$pass + 1L
  } else {
    .results$fail <- .results$fail + 1L
    .results$failures <- c(
      .results$failures,
      sprintf("%s\n    expected: %s\n    actual:   %s",
              label,
              paste(utils::capture.output(dput(expected)), collapse = " "),
              paste(utils::capture.output(dput(actual)),   collapse = " "))
    )
  }
  invisible(ok)
}

expect_true  <- function(label, actual) expect(label, isTRUE(actual), TRUE)
expect_false <- function(label, actual) expect(label, isTRUE(actual), FALSE)

expect_error <- function(label, expr) {
  threw <- inherits(try(force(expr), silent = TRUE), "try-error")
  expect(label, threw, TRUE)
}

# Some behaviour depends on the machine rather than on the code. Skipping
# loudly is honest; asserting it anyway would make the suite fail for
# reasons that are not the report's fault.
skip_unless <- function(label, condition, reason) {
  if (isTRUE(condition)) return(TRUE)
  .results$skip  <- .results$skip + 1L
  .results$skips <- c(.results$skips, sprintf("%s (%s)", label, reason))
  FALSE
}

report_results <- function() {
  cat(sprintf("\n%d passed, %d failed, %d skipped\n",
              .results$pass, .results$fail, .results$skip))
  if (.results$skip > 0L) {
    cat("\nSkipped:\n")
    for (s in .results$skips) cat("  - ", s, "\n", sep = "")
  }
  if (.results$fail > 0L) {
    cat("\nFailures:\n")
    for (f in .results$failures) cat("  - ", f, "\n", sep = "")
    quit(status = 1L)
  }
  invisible(TRUE)
}
