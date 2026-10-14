# A deliberately small assertion harness. The report depends on R, rmarkdown
# and baseballr; the tests add nothing to that list, so anyone who can knit
# the report can run them.

.results <- new.env(parent = emptyenv())
.results$pass <- 0L
.results$fail <- 0L
.results$failures <- character(0)

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

report_results <- function() {
  cat(sprintf("\n%d passed, %d failed\n", .results$pass, .results$fail))
  if (.results$fail > 0L) {
    cat("\nFailures:\n")
    for (f in .results$failures) cat("  - ", f, "\n", sep = "")
    quit(status = 1L)
  }
  invisible(TRUE)
}
