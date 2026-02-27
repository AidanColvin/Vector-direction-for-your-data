count_bad_values <- function(x) {
  # """
  # given a numeric vector
  # return list with na_count and inf_count
  # """
  na_count <- sum(is.na(x))
  inf_count <- sum(is.infinite(x))
  return(list(na_count = na_count, inf_count = inf_count))
}

validate_feature_frame <- function(df, target_col = "diagnosed_diabetes") {
  # """
  # given a feature frame
  # validate no NA and no Inf in predictors
  # return data frame log rows
  # """

  rows <- list()

  for (col in names(df)) {
    if (col == target_col) {
      next
    }

    if (is.numeric(df[[col]])) {
      bad <- count_bad_values(df[[col]])
      rows[[length(rows) + 1]] <- data.frame(
        check = "numeric_validity",
        feature = col,
        na_count = bad$na_count,
        inf_count = bad$inf_count,
        pass = (bad$na_count == 0 && bad$inf_count == 0),
        stringsAsFactors = FALSE
      )
    } else {
      rows[[length(rows) + 1]] <- data.frame(
        check = "type_validity",
        feature = col,
        na_count = sum(is.na(df[[col]])),
        inf_count = 0,
        pass = TRUE,
        stringsAsFactors = FALSE
      )
    }
  }

  return(do.call(rbind, rows))
}

validate_features <- function(input_path, output_path) {
  # """
  # given final vectors csv path
  # validate and save pass/fail log to output_path
  # """

  source("src/io/load_data.R")
  df <- load_dataset(input_path)

  log_df <- validate_feature_frame(df, target_col = "diagnosed_diabetes")

  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  write.csv(log_df, output_path, row.names = FALSE)

  print(paste("saved:", output_path))
}

if (sys.nframe() == 0) {
  validate_features(
    input_path = "data/processed/features_final_extracted_vectors.csv",
    output_path = "data/processed/features_validation_pass_fail_log.csv"
  )
}