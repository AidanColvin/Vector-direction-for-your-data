suppressPackageStartupMessages({
  library(caret); library(readr); library(dplyr)
})

score_path <- "data/processed/tables/comparison/master_scorecard.csv"
if (!file.exists(score_path)) stop("Missing: ", score_path, "\nRun: Rscript generate_all_outputs.R")

# Read master scorecard and pick best by Accuracy (tie-break: AUC then F1)
sc <- read_csv(score_path, show_col_types = FALSE) %>%
  mutate(
    Accuracy = as.numeric(Accuracy),
    AUC = as.numeric(AUC),
    F1 = as.numeric(F1)
  ) %>%
  arrange(desc(Accuracy), desc(AUC), desc(F1))

best <- sc %>% slice(1)
best_name <- best$model[[1]]

cat("\n=== BEST MODEL (by Accuracy) ===\n")
print(best)

# Map scorecard model name -> saved caret model .rds file
rds_map <- c(
  "Logistic Regression" = "models/logistic_regression.rds",
  "Naive Bayes"         = "models/naive_bayes.rds",
  "Random Forest"       = "models/random_forest.rds",
  "Gradient Boosting"   = "models/gradient_boosting.rds",
  "XGBoost"             = "models/xgboost.rds",
  "SVM"                 = "models/svm.rds"
)

if (!best_name %in% names(rds_map)) stop("Unsupported best model name: ", best_name)
best_rds <- rds_map[[best_name]]
if (!file.exists(best_rds)) stop("Missing: ", best_rds)

# Load processed train/test (created by preprocessing in generate_all_outputs.R)
train_path <- "data/processed/train_standardized.csv"
test_path  <- "data/processed/test_standardized.csv"
if (!file.exists(train_path)) stop("Missing: ", train_path)
if (!file.exists(test_path))  stop("Missing: ", test_path)

train <- read_csv(train_path, show_col_types = FALSE)
test  <- read_csv(test_path,  show_col_types = FALSE)

# Expect columns: id + diagnosed_diabetes in train
if (!("diagnosed_diabetes" %in% names(train))) stop("train is missing diagnosed_diabetes")
if (!("id" %in% names(train))) stop("train is missing id")
if (!("id" %in% names(test)))  stop("test is missing id")

# Factorize target to match pipeline convention
train <- train %>%
  mutate(diagnosed_diabetes = factor(ifelse(diagnosed_diabetes == 1, "yes", "no"), levels = c("no","yes")))

# Keep ids for submission; remove id from predictors
test_ids <- test$id
train_x <- train %>% select(-id)
test_x  <- test  %>% select(-id)

# Load the sampled caret model to reuse its tuned hyperparameters/method
m0 <- readRDS(best_rds)

# Train final model on FULL training set using bestTune (no CV)
ctrl_none <- trainControl(method="none", classProbs=TRUE)

cat("\n=== Retraining on FULL train with bestTune (no CV) ===\n")
final_model <- NULL

if (inherits(m0, "train")) {
  meth <- m0$method
  tg   <- m0$bestTune

  if (meth == "glm") {
    final_model <- train(
      diagnosed_diabetes ~ .,
      data = train_x,
      method = "glm",
      family = "binomial",
      trControl = ctrl_none
    )
  } else if (meth == "rf") {
    # keep ntree consistent with your pipeline fast setting (100) unless you want more
    final_model <- train(
      diagnosed_diabetes ~ .,
      data = train_x,
      method = "rf",
      trControl = ctrl_none,
      tuneGrid = tg,
      ntree = 100
    )
  } else if (meth == "gbm") {
    final_model <- train(
      diagnosed_diabetes ~ .,
      data = train_x,
      method = "gbm",
      trControl = ctrl_none,
      tuneGrid = tg,
      verbose = FALSE
    )
  } else if (meth == "xgbTree") {
    final_model <- train(
      diagnosed_diabetes ~ .,
      data = train_x,
      method = "xgbTree",
      trControl = ctrl_none,
      tuneGrid = tg,
      verbosity = 0
    )
  } else if (meth == "svmRadial") {
    final_model <- train(
      diagnosed_diabetes ~ .,
      data = train_x,
      method = "svmRadial",
      trControl = ctrl_none,
      tuneGrid = tg
    )
  } else if (meth == "naive_bayes") {
    final_model <- train(
      diagnosed_diabetes ~ .,
      data = train_x,
      method = "naive_bayes",
      trControl = ctrl_none,
      tuneGrid = tg
    )
  } else {
    stop("Unhandled caret method: ", meth)
  }
} else {
  stop("Loaded RDS is not a caret::train object: ", best_rds)
}

# Predict PROBABILITY of positive class (yes) for Kaggle-style submission
probs_yes <- predict(final_model, test_x, type = "prob")[,"yes"]

# Write comparison outputs to requested locations
dir.create("data/processed/comparison", recursive=TRUE, showWarnings=FALSE)
dir.create("data/processed/submission", recursive=TRUE, showWarnings=FALSE)

# Also create the misspelled folders you asked for (so you get exactly what you wrote)
dir.create("data/prossesed/comparson", recursive=TRUE, showWarnings=FALSE)
dir.create("data/prossesed/submission", recursive=TRUE, showWarnings=FALSE)

comparison_out1 <- "data/processed/comparison/model_comparison_accuracy.csv"
comparison_out2 <- "data/prossesed/comparson/model_comparison_accuracy.csv"
write_csv(sc, comparison_out1)
write_csv(sc, comparison_out2)

# Kaggle-style 2 columns: id + diagnosed_diabetes
sub <- tibble(
  id = test_ids,
  diagnosed_diabetes = probs_yes
)

sub_out1 <- "data/processed/submission/submission.csv"
sub_out2 <- "data/prossesed/submission/submission.csv"
write_csv(sub, sub_out1)
write_csv(sub, sub_out2)

cat("\n=== WROTE FILES ===\n")
cat("Comparison (sorted by Accuracy):\n  - ", comparison_out1, "\n  - ", comparison_out2, "\n", sep="")
cat("Submission (2 cols: id, diagnosed_diabetes):\n  - ", sub_out1, "\n  - ", sub_out2, "\n", sep="")

cat("\n=== TOP 10 MODELS (Accuracy rank) ===\n")
print(sc %>% select(model, Accuracy, AUC, F1, Precision, Recall, Kappa) %>% head(10), n=10)

cat("\n=== SUBMISSION PREVIEW (first 10 rows) ===\n")
print(head(sub, 10), n=10)
