get_numeric_columns <- function(df, exclude = c()) {
  # """
  # given a data frame
  # return vector of numeric column names
  # excludes columns in exclude
  # """
  cols <- names(df)[sapply(df, is.numeric)]
  return(setdiff(cols, exclude))
}

get_categorical_columns <- function(df, exclude = c()) {
  # """
  # given a data frame
  # return vector of categorical column names
  # includes character and factor
  # excludes columns in exclude
  # """
  cols <- names(df)[sapply(df, function(x) is.character(x) || is.factor(x))]
  return(setdiff(cols, exclude))
}

safe_cor <- function(x, y) {
  # """
  # given two numeric vectors
  # return correlation or NA if not computable
  # """
  if (!is.numeric(x) || !is.numeric(y)) {
    return(NA_real_)
  }
  if (length(unique(x[!is.na(x)])) < 2) {
    return(NA_real_)
  }
  if (length(unique(y[!is.na(y)])) < 2) {
    return(NA_real_)
  }
  return(suppressWarnings(cor(x, y, use = "complete.obs")))
}

compute_target_correlations <- function(df, target_col) {
  # """
  # given a data frame and target column
  # return data frame of correlations for numeric predictors vs target
  # """
  numeric_cols <- get_numeric_columns(df, exclude = c(target_col))

  rows <- list()
  for (col in numeric_cols) {
    r <- safe_cor(df[[col]], df[[target_col]])
    rows[[length(rows) + 1]] <- data.frame(
      feature = col,
      metric = "correlation_with_target",
      value = r,
      stringsAsFactors = FALSE
    )
  }

  if (length(rows) == 0) {
    return(data.frame(feature = character(), metric = character(), value = numeric()))
  }

  out <- do.call(rbind, rows)
  out <- out[order(abs(out$value), decreasing = TRUE), ]
  return(out)
}

compute_grouped_numeric_means <- function(df, target_col) {
  # """
  # given a data frame and target column
  # return summary means by target for numeric features
  # """
  numeric_cols <- get_numeric_columns(df, exclude = c(target_col))
  y_vals <- sort(unique(df[[target_col]]))

  rows <- list()
  for (col in numeric_cols) {
    for (y in y_vals) {
      sub <- df[df[[target_col]] == y, , drop = FALSE]
      rows[[length(rows) + 1]] <- data.frame(
        feature = col,
        metric = paste0("mean_when_", target_col, "_equals_", y),
        value = mean(sub[[col]], na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(rows) == 0) {
    return(data.frame(feature = character(), metric = character(), value = numeric()))
  }

  return(do.call(rbind, rows))
}

compute_grouped_category_rates <- function(df, target_col) {
  # """
  # given a data frame and target column
  # return summary rates for categorical features by target
  # """
  cat_cols <- get_categorical_columns(df, exclude = c(target_col))
  y_vals <- sort(unique(df[[target_col]]))

  rows <- list()
  for (col in cat_cols) {
    levels <- sort(unique(as.character(df[[col]])))
    for (lvl in levels) {
      for (y in y_vals) {
        sub <- df[df[[target_col]] == y, , drop = FALSE]
        denom <- nrow(sub)
        num <- sum(as.character(sub[[col]]) == lvl, na.rm = TRUE)
        rate <- if (denom == 0) NA_real_ else num / denom

        rows[[length(rows) + 1]] <- data.frame(
          feature = col,
          metric = paste0("rate_", lvl, "_when_", target_col, "_equals_", y),
          value = rate,
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(rows) == 0) {
    return(data.frame(feature = character(), metric = character(), value = numeric()))
  }

  return(do.call(rbind, rows))
}

find_trends <- function(train_path, target_col, output_path) {
  # """
  # given train csv path, target column, and output path
  # compute trend summaries (correlations and grouped stats)
  # save summary csv to output_path
  # """

  source("src/io/load_data.R")
  df <- load_dataset(train_path)

  if (!(target_col %in% names(df))) {
    stop(paste("target column missing:", target_col))
  }

  # ensure target numeric for correlations
  if (!is.numeric(df[[target_col]])) {
    df[[target_col]] <- as.numeric(as.character(df[[target_col]]))
  }

  cor_df <- compute_target_correlations(df, target_col)
  mean_df <- compute_grouped_numeric_means(df, target_col)
  cat_df <- compute_grouped_category_rates(df, target_col)

  out <- rbind(cor_df, mean_df, cat_df)

  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  write.csv(out, output_path, row.names = FALSE)

  print(paste("saved:", output_path))
}

if (sys.nframe() == 0) {
  find_trends(
    train_path = "data/processed/train_clean.csv",
    target_col = "diagnosed_diabetes",
    output_path = "data/processed/eda_statistical_trends_summary.csv"
  )
}