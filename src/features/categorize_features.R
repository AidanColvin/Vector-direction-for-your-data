bin_bmi <- function(bmi) {
  # """
  # given numeric bmi
  # return bmi category string
  # """

  if (is.na(bmi)) return(NA_character_)
  if (bmi < 18.5) return("underweight")
  if (bmi < 25) return("normal")
  if (bmi < 30) return("overweight")
  return("obese")
}

bin_age <- function(age) {
  # """
  # given numeric age
  # return age group string
  # """

  if (is.na(age)) return(NA_character_)
  if (age < 30) return("under_30")
  if (age < 45) return("30_to_44")
  if (age < 60) return("45_to_59")
  return("60_plus")
}

categorize_features <- function(input_path, output_path) {
  # """
  # given standardized train csv path
  # add categorized features like bmi_bin and age_bin
  # save categorized output to output_path
  # """

  source("src/io/load_data.R")
  df <- load_dataset(input_path)

  if ("bmi" %in% names(df)) {
    df$bmi_bin <- as.factor(vapply(df$bmi, bin_bmi, character(1)))
  }

  if ("age" %in% names(df)) {
    df$age_bin <- as.factor(vapply(df$age, bin_age, character(1)))
  }

  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  write.csv(df, output_path, row.names = FALSE)

  print(paste("saved:", output_path))
}

if (sys.nframe() == 0) {
  categorize_features(
    input_path = "data/processed/train_standardized.csv",
    output_path = "data/processed/features_categorized_variables.csv"
  )
}