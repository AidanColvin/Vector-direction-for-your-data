is_numeric_like <- function(x) {
  # """
  # given a vector
  # return TRUE if values look numeric after trimming
  # ignores NAs and empty strings
  # """

  if (!is.character(x)) {
    return(FALSE)
  }

  vals <- trimws(x)
  vals <- vals[!(is.na(vals) | vals == "")]
  if (length(vals) == 0) {
    return(FALSE)
  }

  # numeric pattern: optional sign, digits, optional decimal
  ok <- grepl("^[-+]?[0-9]*\\.?[0-9]+$", vals)
  return(all(ok))
}

convert_column_to_numeric_safe <- function(df, column_name) {
  # """
  # given a data frame and column name
  # return data frame with column converted to numeric if safe
  # does nothing if column missing or not numeric-like
  # """

  if (!(column_name %in% names(df))) {
    return(df)
  }

  if (is.numeric(df[[column_name]])) {
    return(df)
  }

  if (!is_numeric_like(df[[column_name]])) {
    return(df)
  }

  df[[column_name]] <- suppressWarnings(as.numeric(df[[column_name]]))
  return(df)
}

fix_numeric_types <- function(df) {
  # """
  # given a data frame
  # return data frame with numeric-like text columns converted to numeric
  # scans all columns and converts only safe candidates
  # """

  for (col in names(df)) {
    df <- convert_column_to_numeric_safe(df, col)
  }

  return(df)
}