standardize_train_test <- function(train_df, test_df, exclude = c()) {
  # """
  # given train and test data frames
  # return list with standardized train and test
  # fits scaler on train only then applies to both
  # exclude can remove id or label columns from scaling
  # """

  cols <- get_numeric_columns(train_df, exclude = exclude)

  scaler <- fit_standard_scaler(train_df, cols)

  train_std <- apply_standard_scaler(train_df, scaler)
  test_std  <- apply_standard_scaler(test_df, scaler)

  return(list(train = train_std, test = test_std, scaler = scaler))
}