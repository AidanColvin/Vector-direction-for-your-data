run_full_pipeline <- function() {
  # """
  # run full pipeline
  # cleaning -> encoding -> scaling
  # overwrites processed outputs each run
  # """
  source("src/pipelines/run_cleaning.R")
  run_cleaning_pipeline(na_strategy = "drop")

  source("src/pipelines/run_encoding.R")
  run_encoding_pipeline()

  source("src/pipelines/run_scaling.R")
  run_scaling_pipeline(exclude = c("id", "diagnosed_diabetes"))

  print("pipeline complete")
}

run_full_pipeline()
