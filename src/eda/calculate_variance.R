calculate_variance_report <- function(train_path, output_path, exclude = c()) {
  # """
  # given train csv path and output path
  # compute variance of numeric columns
  # flag near-zero variance columns
  # save csv report
  # """

  source("src/io/load_data.R")
  df <- load_dataset(train_path)

  numeric_cols <- names(df)[sapply(df, is.numeric)]
  numeric_cols <- setdiff(numeric_cols, exclude)

  rows <- list()
  for (col in numeric_cols) {
    v <- var(df[[col]], na.rm = TRUE)
    nzv <- is.na(v) || v < 1e-8

    rows[[length(rows) + 1]] <- data.frame(
      feature = col,
      variance = v,
      near_zero_variance = nzv,
      stringsAsFactors = FALSE
    )
  }

  out <- if (length(rows) == 0) {
    data.frame(feature = character(), variance = numeric(), near_zero_variance = logical())
  } else {
    do.call(rbind, rows)
  }

  out <- out[order(out$variance), ]

  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  write.csv(out, output_path, row.names = FALSE)

  print(paste("saved:", output_path))
}

if (sys.nframe() == 0) {
  calculate_variance_report(
    train_path = "data/processed/train_clean.csv",
    output_path = "data/processed/eda_feature_variance_report.csv",
    exclude = c("id")
  )
}