get_numeric_columns <- function(df, exclude = c()) {
  # """
  # given a data frame
  # return vector of numeric column names
  # excludes any columns listed in exclude
  # """

  numeric_cols <- names(df)[sapply(df, is.numeric)]
  numeric_cols <- setdiff(numeric_cols, exclude)
  return(numeric_cols)
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

  scaler <- list(means = means, sds = sds, columns = columns)
  return(scaler)
}