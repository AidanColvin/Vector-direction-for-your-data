is_binary_numeric <- function(x) {
  # """
  # given a vector
  # return TRUE if numeric and values are only 0/1 (ignoring NA)
  # """
  if (!is.numeric(x)) {
    return(FALSE)
  }
  vals <- unique(x[!is.na(x)])
  if (length(vals) == 0) {
    return(FALSE)
  }
  return(all(vals %in% c(0, 1)))
}

get_continuous_numeric_columns <- function(df, exclude = c()) {
  # """
  # given a data frame
  # return numeric columns that look continuous
  # excludes columns in exclude
  # excludes binary numeric columns (0/1 flags)
  # """
  num_cols <- names(df)[sapply(df, is.numeric)]
  num_cols <- setdiff(num_cols, exclude)

  continuous <- c()
  for (col in num_cols) {
    if (!is_binary_numeric(df[[col]])) {
      continuous <- c(continuous, col)
    }
  }
  return(continuous)
}

fit_standard_scaler <- function(df, columns) {
  # """
  # given a data frame and numeric columns
  # return list with mean and sd for each column
  # sd of 0 is replaced with 1 to avoid divide by zero
  # """
  means <- c()
  sds <- c()

  for (col in columns) {
    mu <- mean(df[[col]], na.rm = TRUE)
    sigma <- sd(df[[col]], na.rm = TRUE)
    if (is.na(sigma) || sigma == 0) {
      sigma <- 1
    }
    means[col] <- mu
    sds[col] <- sigma
  }

  return(list(means = means, sds = sds, columns = columns))
}

apply_standard_scaler <- function(df, scaler) {
  # """
  # given a data frame and a scaler object
  # return standardized data frame
  # uses (x - mean) / sd for each scaler column
  # skips columns not present
  # """
  for (col in scaler$columns) {
    if (!(col %in% names(df))) {
      next
    }
    mu <- scaler$means[[col]]
    sigma <- scaler$sds[[col]]
    df[[col]] <- (df[[col]] - mu) / sigma
  }
  return(df)
}

standardize_train_test <- function(train_df, test_df, exclude = c()) {
  # """
  # given train and test data frames
  # return list with standardized train and test
  # fits scaler on train only then applies to both
  # only standardizes continuous numeric columns
  # """
  cols <- get_continuous_numeric_columns(train_df, exclude = exclude)
  scaler <- fit_standard_scaler(train_df, cols)
  train_std <- apply_standard_scaler(train_df, scaler)
  test_std  <- apply_standard_scaler(test_df, scaler)
  return(list(train = train_std, test = test_std, scaler = scaler))
}
