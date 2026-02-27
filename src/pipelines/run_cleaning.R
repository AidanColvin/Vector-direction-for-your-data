run_cleaning_pipeline <- function(na_strategy = "drop") {
  # """
  # run cleaning pipeline
  # loads raw train and test from data/raw
  # prints NA and blank string reports
  # fixes numeric-like types
  # removes invalid numeric values
  # handles missing values using na_strategy
  # saves cleaned files to data/processed
  # """

  source("src/io/load_data.R")

  source("src/cleaning/check_missing.R")
  source("src/cleaning/fix_types.R")
  source("src/cleaning/handle_invalid.R")
  source("src/cleaning/handle_missing.R")

  # optional: sentinel token checks (safe to include)
  # if file does not exist, skip without failing
  if (file.exists("src/cleaning/check_sentinels.R")) {
    source("src/cleaning/check_sentinels.R")
  }

  train_df <- load_dataset("data/raw/train.csv")
  test_df  <- load_dataset("data/raw/test.csv")

  # ---------------------------
  # report missing values
  # ---------------------------
  print_missing_report(train_df, "train raw")
  print_blank_report(train_df, "train raw")

  print_missing_report(test_df, "test raw")
  print_blank_report(test_df, "test raw")

  # optional: print sentinel token reports if available
  if (exists("print_token_report")) {
    print_token_report(train_df, "train raw", tokens = c("Unknown", "N/A", "NA", "?"))
    print_token_report(test_df,  "test raw",  tokens = c("Unknown", "N/A", "NA", "?"))
  }

  # ---------------------------
  # cleaning steps
  # ---------------------------
  train_df <- fix_numeric_types(train_df)
  test_df  <- fix_numeric_types(test_df)

  train_df <- clean_invalid_values(train_df)
  test_df  <- clean_invalid_values(test_df)

  train_df <- clean_missing_values(train_df, na_strategy = na_strategy)
  test_df  <- clean_missing_values(test_df,  na_strategy = na_strategy)

  # ---------------------------
  # save
  # ---------------------------
  dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

  # overwrite every run
  write.csv(train_df, "data/processed/train_clean.csv", row.names = FALSE)
  write.csv(test_df,  "data/processed/test_clean.csv",  row.names = FALSE)

  print("saved: data/processed/train_clean.csv")
  print("saved: data/processed/test_clean.csv")
}

# run only when executed directly (not when sourced)
if (sys.nframe() == 0) {
  run_cleaning_pipeline(na_strategy = "drop")
}