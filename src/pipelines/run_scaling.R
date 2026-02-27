run_scaling_pipeline <- function(exclude = c("id", "diagnosed_diabetes")) {
  # """
  # run scaling pipeline
  # loads encoded train and test from data/processed
  # standardizes continuous numeric columns using train mean and sd
  # does not standardize binary flags or excluded columns
  # saves standardized files to data/processed
  # prints which continuous columns were standardized
  # """

  source("src/io/load_data.R")
  source("src/scaling/standardize_continuous.R")

  train_df <- load_dataset("data/processed/train_encoded.csv")
  test_df  <- load_dataset("data/processed/test_encoded.csv")

  result <- standardize_train_test(train_df, test_df, exclude = exclude)

  print(paste(
    "standardized continuous columns:",
    paste(result$scaler$columns, collapse = ", ")
  ))

  dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

  write.csv(result$train, "data/processed/train_standardized.csv", row.names = FALSE)
  write.csv(result$test,  "data/processed/test_standardized.csv",  row.names = FALSE)

  print("saved: data/processed/train_standardized.csv")
  print("saved: data/processed/test_standardized.csv")
}

if (sys.nframe() == 0) {
  run_scaling_pipeline(exclude = c("id", "diagnosed_diabetes"))
}