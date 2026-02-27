get_source_calls <- function(root = ".") {
  # """
  # scan repo for source("...") and source('...')
  # return data frame of file, line_number, and target_path
  # """

  r_files <- list.files(root, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  rows <- list()

  for (f in r_files) {
    lines <- readLines(f, warn = FALSE)

    for (i in seq_along(lines)) {
      line <- lines[[i]]

      # skip commented lines
      if (grepl("^\\s*#", line)) {
        next
      }

      # match source("path") or source('path')
      m <- regmatches(line, regexpr("source\\((\"[^\"]+\"|'[^']+')\\)", line, perl = TRUE))
      if (length(m) == 0 || m == "") {
        next
      }

      # extract path between quotes
      p <- sub("^source\\((\"|' )?", "", m)
      p <- sub("^source\\([\"']", "", m)
      p <- sub("[\"']\\)\\s*$", "", p)

      rows[[length(rows) + 1]] <- data.frame(
        file = f,
        line = i,
        target = p,
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(rows) == 0) {
    return(data.frame(file = character(), line = integer(), target = character(), stringsAsFactors = FALSE))
  }

  out <- do.call(rbind, rows)
  return(out)
}

check_sources_exist <- function() {
  # """
  # print missing source() targets with file + line
  # return TRUE if all exist else FALSE
  # """

  calls <- get_source_calls(".")
  if (nrow(calls) == 0) {
    print("OK: no source() calls found")
    return(TRUE)
  }

  missing <- calls[!file.exists(calls$target), , drop = FALSE]

  if (nrow(missing) == 0) {
    print("OK: all source() targets exist")
    return(TRUE)
  }

  print("FAIL: missing source() targets (file:line -> target):")
  for (i in seq_len(nrow(missing))) {
    msg <- paste0(missing$file[[i]], ":", missing$line[[i]], " -> ", missing$target[[i]])
    print(msg)
  }

  return(FALSE)
}

if (sys.nframe() == 0) {
  ok <- check_sources_exist()
  quit(status = if (ok) 0 else 1)
}
