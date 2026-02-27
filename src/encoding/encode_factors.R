source("src/encoding/encode_common_categoricals.R")

convert_to_factors <- function(df, columns) {
  # """
  # given a data frame and a vector of column names
  # return data frame with categorical columns converted
  # converts only columns that exist to factors
  # """

  cols_present <- columns[columns %in% names(df)]
  if (length(cols_present) == 0) {
    return(df)
  }

  df[cols_present] <- lapply(df[cols_present], as.factor)
  return(df)
}

encode_common_columns <- function(df) {
  # """
  # given a data frame
  # return data frame with common text columns converted to factors
  # """

  categorical_cols <- c(
    "gender", "ethnicity", "smoking_status",
    "education_level", "income_level", "employment_status"
  )

  df <- convert_to_factors(df, categorical_cols)
  return(df)
}
source("src/encoding/one_hot_encode.R")

encode_factors_train_test <- function(train_df, test_df, exclude = c()) {
  # """
  # One-hot encode categoricals consistently across train/test.
  #
  # exclude: columns to leave untouched (e.g., id, target label)
  #
  # returns: list(train = encoded_train_df, test = encoded_test_df)
  # """
  stopifnot(is.data.frame(train_df))
  stopifnot(is.data.frame(test_df))

  fit <- one_hot_fit(train_df, exclude = exclude)

  train_mm <- one_hot_apply(train_df, fit, exclude = exclude)
  test_mm  <- one_hot_apply(test_df,  fit, exclude = exclude)

  # keep excluded columns (in original order)
  keep_train <- train_df[, intersect(exclude, names(train_df)), drop = FALSE]
  keep_test  <- test_df[,  intersect(exclude, names(test_df)),  drop = FALSE]

  out_train <- cbind(keep_train, train_mm)
  out_test  <- cbind(keep_test,  test_mm)

  return(list(train = out_train, test = out_test))
}
