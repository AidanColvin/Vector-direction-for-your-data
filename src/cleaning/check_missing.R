count_missing_by_column <- function(df) {
  # """
  # given a data frame
  # return named vector of NA counts per column
  # """

  return(colSums(is.na(df)))
}

has_any_missing <- function(df) {
  # """
  # given a data frame
  # return TRUE if any missing values exist else FALSE
  # """

  return(any(is.na(df)))
}

count_blank_strings_by_column <- function(df) {
  # """
  # given a data frame
  # return named vector of blank string counts per column
  # counts "" and whitespace-only strings in character columns
  # """

  out <- rep(0, ncol(df))
  names(out) <- names(df)

  for (col in names(df)) {
    if (is.character(df[[col]])) {
      vals <- trimws(df[[col]])
      out[col] <- sum(vals == "" | is.na(vals))
    }
  }

  return(out)
}

print_missing_report <- function(df, name = "data") {
  # """
  # given a data frame and display name
  # print missing value counts
  # """

  print(paste(name, "missing counts:"))
  print(count_missing_by_column(df))
}

print_blank_report <- function(df, name = "data") {
  # """
  # given a data frame and display name
  # print blank string counts
  # """

  print(paste(name, "blank string counts:"))
  print(count_blank_strings_by_column(df))
}
count_missing_by_column <- function(df) {
  # """
  # given a data frame
  # return named vector of NA counts per column
  # """
  return(colSums(is.na(df)))
}
