normalize_tokens_to_na <- function(df, tokens = c("Unknown", "N/A", "NA", "?")) {
  # """
  # given a data frame
  # normalize common sentinel tokens to NA (character columns only)
  # return updated data frame
  # """
  char_cols <- names(df)[sapply(df, is.character)]
  for (col in char_cols) {
    x <- df[[col]]
    x <- trimws(x)
    x[x %in% tokens] <- NA
    x[x == ""] <- NA
    df[[col]] <- x
  }
  return(df)
}

encode_common_categoricals <- function(train_df, test_df = NULL) {
  # """
  # given train and optional test data frames
  # convert character columns to factors with safe, consistent levels
  #
  # behavior:
  # - if test_df is NULL: factorize within train_df only
  # - if test_df provided: factor levels are the union(train,test) so model.matrix won't break
  #
  # returns:
  # - if test_df is NULL: data.frame
  # - else: list(train = ..., test = ...)
  # """

  train_df <- normalize_tokens_to_na(train_df)

  if (is.null(test_df)) {
    char_cols <- names(train_df)[sapply(train_df, is.character)]
    for (col in char_cols) {
      lvls <- sort(unique(train_df[[col]]))
      lvls <- lvls[!is.na(lvls)]
      train_df[[col]] <- factor(train_df[[col]], levels = lvls)
    }
    return(train_df)
  }

  test_df <- normalize_tokens_to_na(test_df)

  char_cols <- names(train_df)[sapply(train_df, is.character)]
  for (col in char_cols) {
    lvls <- sort(unique(c(train_df[[col]], test_df[[col]])))
    lvls <- lvls[!is.na(lvls)]
    train_df[[col]] <- factor(train_df[[col]], levels = lvls)
    test_df[[col]]  <- factor(test_df[[col]],  levels = lvls)
  }

  return(list(train = train_df, test = test_df))
}
