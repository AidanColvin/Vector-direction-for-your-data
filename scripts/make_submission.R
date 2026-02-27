suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(caret)
})

# -----------------------------
# inputs
# -----------------------------
score_path <- "data/processed/tables/comparison/master_scorecard.csv"
train_path <- "data/processed/train_standardized.csv"
test_path  <- "data/processed/test_standardized.csv"

if (!file.exists(score_path)) stop("Missing: ", score_path, "\nRun: Rscript generate_all_outputs.R")
if (!file.exists(train_path)) stop("Missing: ", train_path)
if (!file.exists(test_path))  stop("Missing: ", test_path)

# -----------------------------
# choose best model (Accuracy, then AUC, then F1)
# -----------------------------
sc <- read_csv(score_path, show_col_types = FALSE) %>%
  mutate(
    Accuracy = as.numeric(Accuracy),
    AUC      = as.numeric(AUC),
    F1       = as.numeric(F1)
  ) %>%
  arrange(desc(Accuracy), desc(AUC), desc(F1))

best <- sc %>% slice(1)
best_name <- best$model[[1]]

cat("\n=== BEST MODEL (by Accuracy) ===\n")
print(best)

rds_map <- c(
  "Logistic Regression" = "models/logistic_regression.rds",
  "Naive Bayes"         = "models/naive_bayes.rds",
  "Random Forest"       = "models/random_forest.rds",
  "Gradient Boosting"   = "models/gradient_boosting.rds",
  "XGBoost"             = "models/xgboost.rds",
  "SVM"                 = "models/svm.rds"
)

if (!best_name %in% names(rds_map)) stop("Unsupported best model name in scorecard: ", best_name)
best_rds <- rds_map[[best_name]]
if (!file.exists(best_rds)) stop("Missing model file: ", best_rds)

# -----------------------------
# load processed data
# -----------------------------
train <- read_csv(train_path, show_col_types = FALSE)
test  <- read_csv(test_path,  show_col_types = FALSE)

if (!("diagnosed_diabetes" %in% names(train))) stop("train missing diagnosed_diabetes")
if (!("id" %in% names(train))) stop("train missing id")
if (!("id" %in% names(test)))  stop("test missing id")

train <- train %>%
  mutate(diagnosed_diabetes = factor(ifelse(diagnosed_diabetes == 1, "yes", "no"), levels = c("no","yes")))

test_ids <- test$id
train_x <- train %>% select(-id)
test_x  <- test  %>% select(-id)

# -----------------------------
# retrain best model on full train (no CV) and predict probabilities
# -----------------------------
m0 <- readRDS(best_rds)
if (!inherits(m0, "train")) stop("Model RDS is not a caret::train object: ", best_rds)

ctrl_none <- trainControl(method = "none", classProbs = TRUE)
meth <- m0$method
tg   <- m0$bestTune

cat("\n=== Retraining on FULL train (no CV) ===\n")

if (meth == "glm") {
  final_model <- train(diagnosed_diabetes ~ ., data = train_x, method = "glm", family = "binomial", trControl = ctrl_none)
} else if (meth == "rf") {
  final_model <- train(diagnosed_diabetes ~ ., data = train_x, method = "rf", trControl = ctrl_none, tuneGrid = tg, ntree = 100)
} else if (meth == "gbm") {
  final_model <- train(diagnosed_diabetes ~ ., data = train_x, method = "gbm", trControl = ctrl_none, tuneGrid = tg, verbose = FALSE)
} else if (meth == "xgbTree") {
  final_model <- train(diagnosed_diabetes ~ ., data = train_x, method = "xgbTree", trControl = ctrl_none, tuneGrid = tg, verbosity = 0)
} else if (meth == "svmRadial") {
  final_model <- train(diagnosed_diabetes ~ ., data = train_x, method = "svmRadial", trControl = ctrl_none, tuneGrid = tg)
} else if (meth == "naive_bayes") {
  final_model <- train(diagnosed_diabetes ~ ., data = train_x, method = "naive_bayes", trControl = ctrl_none, tuneGrid = tg)
} else {
  stop("Unhandled caret method: ", meth)
}

probs_yes <- predict(final_model, test_x, type = "prob")[, "yes"]

# -----------------------------
# save submission EXACT PATH
# -----------------------------
dir.create("data/processed/submission", recursive = TRUE, showWarnings = FALSE)

submission <- tibble(
  id = test_ids,
  diagnosed_diabetes = probs_yes
)

out_path <- "data/processed/submission/submission.csv"
write_csv(submission, out_path)

cat("\n=== SUBMISSION SAVED ===\n")
cat(out_path, "\n")

cat("\n=== PREVIEW (first 10 rows) ===\n")
print(head(submission, 10), n = 10)
