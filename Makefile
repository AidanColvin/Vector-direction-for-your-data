run_full_pipeline <- function() {
  # """
  # run full pipeline
  # cleaning -> encoding -> standardization
  # overwrites processed outputs each run
  # """

  source("scripts/run_cleaning.R")
  run_cleaning_pipeline(na_strategy = "drop")

  source("scripts/run_encoding.R")
  run_encoding_pipeline()

  source("scripts/run_standardization.R")
  run_standardization_pipeline(exclude = c("id", "diagnosed_diabetes"))

  print("pipeline complete")
}

run_full_pipeline()