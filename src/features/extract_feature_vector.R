select_feature_columns <- function(df, target_col = "diagnosed_diabetes", drop_cols = c("id")) {
  # """
  # given a data frame
  # return list with x_cols and y_col
  # drops id and target from x
  # """

  x_cols <- setdiff(names(df), c(drop_cols, target_col))
  return(list(x_cols = x_cols, y_col = target_col))
}

extract_feature_vector <- function(input_path, output_path, target_col = "diagnosed_diabetes") {
  # """
  # given categorized train csv path
  # build final feature matrix (model-ready)
  # one-hot encodes factors via model.matrix
  # saves combined feature vectors to output_path
  # """

  source("src/io/load_data.R")
  df <- load_dataset(input_path)

  if (!(target_col %in% names(df))) {
    stop(paste("target column missing:", target_col))
  }

  cols <- select_feature_columns(df, target_col = target_col, drop_cols = c("id"))
  x_df <- df[, cols$x_cols, drop = FALSE]
  y <- df[[target_col]]

  # ensure factors are factors
  for (col in names(x_df)) {
    if (is.character(x_df[[col]])) {
      x_df[[col]] <- as.factor(x_df[[col]])
    }
  }

  # build design matrix
  x_mat <- model.matrix(~ . , data = x_df)
  x_mat <- x_mat[, colnames(x_mat) != "(Intercept)", drop = FALSE]

  out <- data.frame(x_mat, diagnosed_diabetes = y, check.names = FALSE)

  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  write.csv(out, output_path, row.names = FALSE)

  print(paste("saved:", output_path))
}

if (sys.nframe() == 0) {
  extract_feature_vector(
    input_path = "data/processed/features_categorized_variables.csv",
    output_path = "data/processed/features_final_extracted_vectors.csv",
    target_col = "diagnosed_diabetes"
  )
}