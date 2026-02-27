options(warn=1)
msg <- function(...) cat(..., "\n", sep="")
die <- function(...) { msg("ERROR: ", ...); quit(status=1) }

req <- c("readr","dplyr","caret","tibble")
missing <- req[!req %in% rownames(installed.packages())]
if (length(missing)) install.packages(missing, repos="https://cloud.r-project.org")

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(caret); library(tibble)
})

test_path   <- "data/processed/test_standardized.csv"
sample_path <- "data/raw/sample_submission.csv"
out_path    <- "data/processed/submission/submission.csv"

if (!file.exists(test_path))   die("Missing ", test_path)
if (!file.exists(sample_path)) die("Missing ", sample_path)

test   <- read_csv(test_path, show_col_types=FALSE)
sample <- read_csv(sample_path, show_col_types=FALSE)

id_col     <- names(sample)[1]
target_col <- names(sample)[2]

if (!("id" %in% names(test))) die("test_standardized.csv must contain column: id")

x <- test %>% select(-id)
n <- nrow(test)

# Order: most reliable first; SVM last (often fails prob)
candidates <- c(
  "models/logistic_regression.rds",
  "models/random_forest.rds",
  "models/gradient_boosting.rds",
  "models/naive_bayes.rds",
  "models/svm.rds"
)
candidates <- candidates[file.exists(candidates)]
if (!length(candidates)) die("No model .rds files found in ./models")

pick_pred <- function(model) {
  if (inherits(model, "train")) {
    pr <- try(predict(model, x, type="prob"), silent=TRUE)
    if (!inherits(pr, "try-error") && is.data.frame(pr) && ncol(pr) >= 2) {
      p <- if ("yes" %in% names(pr)) pr[["yes"]] else pr[[2]]
      if (length(p) == n && !all(is.na(p))) return(p)
    }
    cls <- try(predict(model, x), silent=TRUE)
    if (!inherits(cls, "try-error") && length(cls) == n) {
      if (is.factor(cls)) cls <- as.character(cls)
      return(ifelse(cls %in% c("yes","1","TRUE",1), 1, 0))
    }
    return(NULL)
  } else {
    pr <- try(predict(model, x), silent=TRUE)
    if (inherits(pr, "try-error")) return(NULL)
    if (length(pr) != n) return(NULL)
    if (is.numeric(pr) && !all(is.na(pr))) return(pr)
    return(ifelse(pr %in% c("yes","1","TRUE",1), 1, 0))
  }
}

pred <- NULL
picked <- NULL

for (p in candidates) {
  msg("Trying model: ", p)
  m <- try(readRDS(p), silent=TRUE)
  if (inherits(m, "try-error")) { msg("  - load failed, skipping"); next }
  pp <- pick_pred(m)
  if (is.null(pp)) { msg("  - prediction failed/NA/wrong length, skipping"); next }
  pred <- pp
  picked <- p
  break
}

if (is.null(pred)) die("No saved model produced valid predictions for n=", n)

submission <- tibble(
  !!id_col := test$id,
  !!target_col := pred
)

dir.create("data/processed/submission", recursive=TRUE, showWarnings=FALSE)
write_csv(submission, out_path)

msg("\n=== SUBMISSION SAVED ===")
msg(out_path)
msg("Model used: ", picked)
