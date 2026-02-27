require_random_forest <- function() {
  # """
  # ensure randomForest package exists
  # stop with helpful message if missing
  # """

  if (!requireNamespace("randomForest", quietly = TRUE)) {
    stop("missing package: randomForest. install with: install.packages('randomForest')")
  }
}

prepare_rf_frame <- function(df, target_col, drop_cols = c()) {
  # """
  # given a data frame
  # return frame ready for random forest importance
  # converts character to factor
  # drops columns listed in drop_cols
  # removes rows with NA
  # """

  keep <- setdiff(names(df), drop_cols)
  df <- df[, keep, drop = FALSE]

  for (col in names(df)) {
    if (is.character(df[[col]])) {
      df[[col]] <- as.factor(df[[col]])
    }
  }

  df <- na.omit(df)

  if (!(target_col %in% names(df))) {
    stop(paste("target column missing:", target_col))
  }

  df[[target_col]] <- as.factor(df[[target_col]])

  return(df)
}

rf_feature_importance <- function(train_path, target_col, output_path, drop_cols = c("id")) {
  # """
  # given train csv path and target column
  # train random forest for feature importance only
  # save importance report to output_path
  # """

  require_random_forest()
  source("src/io/load_data.R")

  df <- load_dataset(train_path)
  df <- prepare_rf_frame(df, target_col, drop_cols = drop_cols)

  # model formula: target ~ .
  form <- as.formula(paste(target_col, "~ ."))

  set.seed(7)
  model <- randomForest::randomForest(
    form,
    data = df,
    ntree = 300,
    importance = TRUE
  )

  imp <- randomForest::importance(model)
  imp_df <- data.frame(
    feature = rownames(imp),
    imp,
    row.names = NULL,
    stringsAsFactors = FALSE
  )

  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  write.csv(imp_df, output_path, row.names = FALSE)

  print(paste("saved:", output_path))
}

if (sys.nframe() == 0) {
  rf_feature_importance(
    train_path = "data/processed/train_encoded.csv",
    target_col = "diagnosed_diabetes",
    output_path = "data/processed/eda_rf_feature_impact_scores.csv",
    drop_cols = c("id")
  )
}