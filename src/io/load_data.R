load_dataset <- function(file_path) {
  # """
  # given a file path
  # return dataframe loaded from csv
  # stop if file does not exist
  # """

  if (!file.exists(file_path)) {
    stop(paste("file not found:", file_path))
  }

  df <- read.csv(file_path, stringsAsFactors = FALSE)
  return(df)
}

load_train_data <- function() {
  # """
  # load training dataset from data/raw/train.csv
  # return dataframe
  # """
  return(load_dataset("data/raw/train.csv"))
}

load_test_data <- function() {
  # """
  # load test dataset from data/raw/test.csv
  # return dataframe
  # """
  return(load_dataset("data/raw/test.csv"))
}