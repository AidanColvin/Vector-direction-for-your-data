run_features_pipeline <- function() {
  # """
  # run features pipeline (robust + memory-safe)
  # - reads standardized train/test
  # - converts categoricals to integer codes (NO model.matrix contrasts errors)
  # - writes required feature artifacts
  # """

  dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

  train_path <- "data/processed/train_standardized.csv"
  test_path  <- "data/processed/test_standardized.csv"
  if (!file.exists(train_path)) stop("Missing input: ", train_path)
  if (!file.exists(test_path))  stop("Missing input: ", test_path)

  train_df <- read.csv(train_path, stringsAsFactors = FALSE)
  test_df  <- read.csv(test_path,  stringsAsFactors = FALSE)

  # Categorize variables
  cols <- names(train_df)
  target <- "diagnosed_diabetes"
  idcol  <- "id"

  numeric_cols <- cols[sapply(train_df, is.numeric)]
  cat_cols <- setdiff(cols, c(numeric_cols, target))

  categorized <- data.frame(
    variable = cols,
    kind = ifelse(cols %in% c(target), "target",
                 ifelse(cols %in% c(idcol), "id",
                        ifelse(cols %in% numeric_cols, "numeric", "categorical"))),
    stringsAsFactors = FALSE
  )
  write.csv(categorized, "data/processed/features_categorized_variables.csv", row.names = FALSE)
  print("saved: data/processed/features_categorized_variables.csv")

  # Convert categoricals to integer codes safely
  # - works even if a column has 1 unique level
  to_codes <- function(df) {
    for (c in names(df)) {
      if (c %in% c(target)) next
      if (is.character(df[[c]])) df[[c]] <- trimws(df[[c]])
      if (is.character(df[[c]]) || is.factor(df[[c]])) {
        # keep NA as NA, otherwise integer codes starting at 0
        f <- factor(df[[c]])
        df[[c]] <- ifelse(is.na(df[[c]]), NA_integer_, as.integer(f) - 1L)
      }
    }
    df
  }

  train_feat <- to_codes(train_df)
  test_feat  <- to_codes(test_df)

  # Validation log
  log_rows <- list()
  add_log <- function(step, ok, note="") {
    log_rows[[length(log_rows)+1]] <<- data.frame(step=step, ok=ok, note=note, stringsAsFactors=FALSE)
  }

  # Basic checks
  add_log("has_train_rows", nrow(train_feat) > 0, paste0("n=", nrow(train_feat)))
  add_log("has_test_rows",  nrow(test_feat)  > 0, paste0("n=", nrow(test_feat)))
  add_log("has_target", target %in% names(train_feat), "")
  add_log("same_columns_train_test",
          identical(setdiff(names(train_feat), target), names(test_feat)),
          "")

  val <- do.call(rbind, log_rows)
  write.csv(val, "data/processed/features_validation_pass_fail_log.csv", row.names = FALSE)
  print("saved: data/processed/features_validation_pass_fail_log.csv")

  # Final extracted vectors (keep id if present; keep target in train only)
  write.csv(train_feat, "data/processed/features_final_extracted_vectors.csv", row.names = FALSE)
  print("saved: data/processed/features_final_extracted_vectors.csv")
}

if (sys.nframe() == 0) {
  run_features_pipeline()
}
