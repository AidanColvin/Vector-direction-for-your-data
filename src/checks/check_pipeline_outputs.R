safe_source <- function(path) {
  # """
  # given a path
  # source it or stop with clear message
  # """
  if (!file.exists(path)) {
    stop(paste("missing file:", path))
  }
  source(path)
}

file_exists <- function(path) {
  # """
  # given a file path
  # return TRUE if exists else FALSE
  # """
  return(file.exists(path))
}

check_outputs <- function(paths) {
  # """
  # given expected output paths
  # return list(ok=bool, missing=chr)
  # """
  missing <- c()
  for (p in paths) {
    if (!file_exists(p)) missing <- c(missing, p)
  }
  return(list(ok = length(missing) == 0, missing = missing))
}

run_all_pipelines <- function() {
  # """
  # run all pipeline runners in order
  # cleaning -> encoding -> scaling -> eda -> features
  # """
  safe_source("src/pipelines/run_cleaning.R")
  run_cleaning_pipeline(na_strategy = "drop")

  safe_source("src/pipelines/run_encoding.R")
  run_encoding_pipeline()

  safe_source("src/pipelines/run_scaling.R")
  run_scaling_pipeline(exclude = c("id", "diagnosed_diabetes"))

  safe_source("src/pipelines/run_eda.R")
  run_eda_pipeline()

  safe_source("src/pipelines/run_features.R")
  run_features_pipeline()
}

main <- function() {
  # """
  # run pipelines + verify expected outputs
  # prints FAIL/OK; never hard-crashes terminal
  # """
  dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

  expected <- c(
    "data/processed/train_clean.csv",
    "data/processed/test_clean.csv",
    "data/processed/train_encoded.csv",
    "data/processed/test_encoded.csv",
    "data/processed/train_standardized.csv",
    "data/processed/test_standardized.csv",
    "data/processed/eda_statistical_trends_summary.csv",
    "data/processed/eda_feature_variance_report.csv",
    "data/processed/eda_rf_feature_impact_scores.csv",
    "data/processed/features_categorized_variables.csv",
    "data/processed/features_final_extracted_vectors.csv",
    "data/processed/features_validation_pass_fail_log.csv"
  )

  ok_run <- TRUE
  err_msg <- NULL

  tryCatch(
    run_all_pipelines(),
    error = function(e) {
      ok_run <<- FALSE
      err_msg <<- e$message
    }
  )

  out <- check_outputs(expected)

  if (ok_run && out$ok) {
    print("OK: pipelines ran and all expected outputs exist")
  } else {
    print("FAIL: pipeline outputs check failed")

    if (!ok_run) {
      print("FAIL: pipeline execution error:")
      print(err_msg)
    }

    if (!out$ok) {
      print("FAIL: missing outputs:")
      print(out$missing)
    }
  }

  # IMPORTANT: do not kill the VS Code terminal process
  return(invisible(NULL))
}

if (sys.nframe() == 0) {
  main()
}
