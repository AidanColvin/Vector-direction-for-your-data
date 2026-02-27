one_hot_fit <- function(df, exclude = c()) {
  # """
  # given a data frame
  # build a model.matrix() design spec for one-hot encoding
  # returns list(terms = terms_obj, cols = character vector)
  # """
  use_df <- df
  if (length(exclude) > 0) {
    keep <- setdiff(names(use_df), exclude)
    use_df <- use_df[, keep, drop = FALSE]
  }

  # convert character -> factor (levels already aligned earlier if you want)
  char_cols <- names(use_df)[sapply(use_df, is.character)]
  for (col in char_cols) use_df[[col]] <- factor(use_df[[col]])

  f <- as.formula("~ . - 1")
  mm <- model.matrix(f, data = use_df)
  return(list(terms = terms(f, data = use_df), cols = colnames(mm)))
}

one_hot_apply <- function(df, fit, exclude = c()) {
  # """
  # given a data frame + fit from one_hot_fit()
  # return numeric data.frame with the SAME columns as fit$cols
  # """
  use_df <- df
  if (length(exclude) > 0) {
    keep <- setdiff(names(use_df), exclude)
    use_df <- use_df[, keep, drop = FALSE]
  }

  char_cols <- names(use_df)[sapply(use_df, is.character)]
  for (col in char_cols) use_df[[col]] <- factor(use_df[[col]])

  mm <- model.matrix(fit$terms, data = use_df)
  mm <- as.data.frame(mm)

  # add missing columns
  missing <- setdiff(fit$cols, colnames(mm))
  for (m in missing) mm[[m]] <- 0

  # drop extra columns + reorder
  mm <- mm[, fit$cols, drop = FALSE]
  return(mm)
}
