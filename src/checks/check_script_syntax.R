syntax_check_all <- function(root = "src") {
  # """
  # parse every .R file under root
  # print files that fail parsing
  # return TRUE if all parse else FALSE
  # """
  r_files <- list.files(root, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  bad <- c()

  for (f in r_files) {
    ok <- TRUE
    tryCatch(
      parse(file = f),
      error = function(e) { ok <<- FALSE }
    )
    if (!ok) {
      bad <- c(bad, f)
    }
  }

  if (length(bad) == 0) {
    print("OK: all scripts parse")
    return(TRUE)
  }

  print("FAIL: scripts with syntax errors:")
  print(bad)
  return(FALSE)
}

if (sys.nframe() == 0) {
  ok <- syntax_check_all("src")
  quit(status = if (ok) 0 else 1)
}
