apply_standard_scaler <- function(df, scaler) {
  # """
  # given a data frame and a scaler object
  # return standardized data frame
  # uses (x - mean) / sd for each scaler column
  # skips columns not present
  # """

  cols <- scaler$columns

  for (col in cols) {
    if (!(col %in% names(df))) {
      next
    }

    mu <- scaler$means[[col]]
    sigma <- scaler$sds[[col]]

    df[[col]] <- (df[[col]] - mu) / sigma
  }

  return(df)
}