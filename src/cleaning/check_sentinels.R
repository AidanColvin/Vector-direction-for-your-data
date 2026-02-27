count_token_by_column <- function(df, token) {
  # """
  # given a data frame and a token string
  # return named vector of counts per column where value equals token
  # checks character and factor columns
  # """

  out <- rep(0, ncol(df))
  names(out) <- names(df)

  for (col in names(df)) {
    if (is.character(df[[col]]) || is.factor(df[[col]])) {
      out[col] <- sum(as.character(df[[col]]) == token, na.rm = TRUE)
    }
  }

  return(out)
}

print_token_report <- function(df, name = "data", tokens = c("Unknown", "N/A", "NA", "?")) {
  # """
  # given a data frame and display name
  # print token counts for common missing value markers
  # """

  for (t in tokens) {
    print(paste(name, "token counts for:", t))
    print(count_token_by_column(df, t))
  }
}