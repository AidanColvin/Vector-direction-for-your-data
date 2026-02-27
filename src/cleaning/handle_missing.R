remove_missing_rows <- function(df) {
  # """
  # given a data frame
  # return data frame with missing values removed
  # drops any row containing an NA
  # """
  return(na.omit(df))
}

impute_numeric_median <- function(df, column_name) {
  # """
  # given a data frame and a numeric column name
  # return data frame with missing values imputed
  # replaces NA with the median of the column
  # """

  if (!(column_name %in% names(df))) {
    stop(paste("column not found:", column_name))
  }

  if (!is.numeric(df[[column_name]])) {
    stop(paste("column is not numeric:", column_name))
  }

  column_median <- median(df[[column_name]], na.rm = TRUE)
  df[[column_name]][is.na(df[[column_name]])] <- column_median
  return(df)
}

impute_all_numeric_median <- function(df) {
  # """
  # given a data frame
  # return data frame with NA in numeric columns imputed by median
  # leaves non-numeric columns unchanged
  # """

  numeric_cols <- names(df)[sapply(df, is.numeric)]

  for (col in numeric_cols) {
    if (any(is.na(df[[col]]))) {
      df <- impute_numeric_median(df, col)
    }
  }

  return(df)
}

clean_missing_values <- function(df, na_strategy = "drop") {
  # """
  # given a data frame
  # return data frame with missing values handled
  # na_strategy = 'drop' removes rows with any NA
  # na_strategy = 'median' imputes numeric NAs using median
  # """

  if (na_strategy == "drop") {
    return(remove_missing_rows(df))
  }

  if (na_strategy == "median") {
    return(impute_all_numeric_median(df))
  }

  stop(paste("unknown na_strategy:", na_strategy))
}
remove_missing_rows <- function(df) {
  # """
  # given a data frame
  # return data frame with missing values removed
  # drops any row containing an NA
  # """
  return(na.omit(df))
}

impute_numeric_median <- function(df, column_name) {
  # """
  # given a data frame and a numeric column name
  # return data frame with missing values imputed
  # replaces NA with the median of the column
  # """

  if (!(column_name %in% names(df))) {
    stop(paste("column not found:", column_name))
  }

  if (!is.numeric(df[[column_name]])) {
    stop(paste("column is not numeric:", column_name))
  }

  column_median <- median(df[[column_name]], na.rm = TRUE)
  df[[column_name]][is.na(df[[column_name]])] <- column_median
  return(df)
}

impute_all_numeric_median <- function(df) {
  # """
  # given a data frame
  # return data frame with NA in numeric columns imputed by median
  # leaves non-numeric columns unchanged
  # """

  num_cols <- names(df)[sapply(df, is.numeric)]

  for (col in num_cols) {
    if (any(is.na(df[[col]]))) {
      df <- impute_numeric_median(df, col)
    }
  }

  return(df)
}
