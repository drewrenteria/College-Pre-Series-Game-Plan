# Pull individual function definitions out of the .Rmd without running the
# report. The report is one file by design, so there is no package to load:
# these tests read the source, slice out the functions by name, and evaluate
# only those. Nothing here touches the network or the cache.

extract_functions <- function(rmd_path, fn_names) {
  lines <- readLines(rmd_path, warn = FALSE)
  closers <- grep("^\\}", lines)
  out <- character(0)

  for (nm in fn_names) {
    pattern <- paste0("^", gsub("([.\\\\])", "\\\\\\1", nm), "\\s*<-\\s*function")
    start <- grep(pattern, lines)
    if (length(start) == 0L) {
      stop("function not found in ", basename(rmd_path), ": ", nm, call. = FALSE)
    }
    start <- start[[1L]]

    if (!grepl("\\{", lines[[start]])) {
      end <- start                       # one-liner, no brace block
    } else {
      after <- closers[closers >= start]
      if (length(after) == 0L) {
        stop("no closing brace at column 0 for: ", nm, call. = FALSE)
      }
      end <- after[[1L]]
    }
    out <- c(out, lines[start:end], "")
  }
  out
}

load_report_functions <- function(fn_names, rmd_path = NULL) {
  if (is.null(rmd_path)) {
    here <- c("opponent_advance_report.Rmd", "../opponent_advance_report.Rmd")
    hit  <- here[file.exists(here)]
    if (length(hit) == 0L) {
      stop("cannot find opponent_advance_report.Rmd; run from the repo root ",
           "or the tests/ folder", call. = FALSE)
    }
    rmd_path <- hit[[1L]]
  }
  env <- new.env(parent = globalenv())
  eval(parse(text = extract_functions(rmd_path, fn_names)), envir = env)
  env
}
