remove_infinite_numeric <- function(df) {
  # """
  # given a data frame
  # return data frame with rows containing Inf/-Inf/NaN in numeric cols removed
  # """

  numeric_cols <- names(df)[sapply(df, is.numeric)]
  if (length(numeric_cols) == 0) {
    return(df)
  }

  keep <- rep(TRUE, nrow(df))

  for (col in numeric_cols) {
    x <- df[[col]]
    bad <- is.infinite(x) | is.nan(x)
    keep <- keep & !bad
  }

  df <- df[keep, , drop = FALSE]
  return(df)
}

clean_invalid_values <- function(df) {
  # """
  # given a data frame
  # return data frame with basic invalid numeric values removed
  # """

  df <- remove_infinite_numeric(df)
  return(df)
}