run_encoding_pipeline <- function() {
  # """
  # run encoding pipeline
  # loads cleaned train and test from data/processed
  # applies consistent factor levels across train/test
  # saves encoded files to data/processed
  # """

  source("src/io/load_data.R")
  source("src/encoding/encode_factors.R")
  source("src/encoding/encode_common_categoricals.R")

  train_df <- load_dataset("data/processed/train_clean.csv")
  test_df  <- load_dataset("data/processed/test_clean.csv")

  tmp <- encode_common_categoricals(train_df, test_df)
  train_df <- tmp$train
  test_df  <- tmp$test

  # Optional: if encode_factors.R does additional work, apply it here.
  # If encode_factors.R already includes everything you need, remove these two lines.
  # train_df <- encode_factors(train_df)
  # test_df  <- encode_factors(test_df)

  write.csv(train_df, "data/processed/train_encoded.csv", row.names = FALSE)
  write.csv(test_df,  "data/processed/test_encoded.csv",  row.names = FALSE)

  print("saved: data/processed/train_encoded.csv")
  print("saved: data/processed/test_encoded.csv")
}

if (sys.nframe() == 0) {
  run_encoding_pipeline()
}
