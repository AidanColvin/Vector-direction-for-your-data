options(warn=1)

msg <- function(...) cat(..., "\n", sep="")
die <- function(...) { msg("ERROR: ", ...); quit(status=1) }

req <- c("readr","dplyr","caret","pROC","tibble")
missing <- req[!req %in% rownames(installed.packages())]
if (length(missing)) install.packages(missing, repos="https://cloud.r-project.org")

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(caret); library(pROC); library(tibble)
})

set.seed(42)

# Inputs
train_path  <- "data/processed/train_standardized.csv"
test_path   <- "data/processed/test_standardized.csv"
sample_path <- "data/raw/sample_submission.csv"

if (!file.exists(train_path))  die("Missing ", train_path)
if (!file.exists(test_path))   die("Missing ", test_path)
if (!file.exists(sample_path)) die("Missing ", sample_path)

train <- read_csv(train_path, show_col_types=FALSE)
test  <- read_csv(test_path,  show_col_types=FALSE)
sample <- read_csv(sample_path, show_col_types=FALSE)

# Columns
id_col <- names(sample)[1]
target_col <- names(sample)[2]

if (!("id" %in% names(train))) die("train_standardized.csv missing id")
if (!("diagnosed_diabetes" %in% names(train))) die("train_standardized.csv missing diagnosed_diabetes")
if (!("id" %in% names(test))) die("test_standardized.csv missing id")

# Prepare target as factor (caret classification)
train <- train %>%
  mutate(diagnosed_diabetes = factor(ifelse(diagnosed_diabetes == 1, "yes", "no"), levels=c("no","yes")))

# Train/Val split 80/20
idx <- createDataPartition(train$diagnosed_diabetes, p=0.80, list=FALSE)
trn <- train[idx, ]
val <- train[-idx, ]

# Drop id from predictors
trn_x <- trn %>% select(-id)
val_x <- val %>% select(-id)

# 5-fold CV inside the 80% training split
ctrl <- trainControl(
  method = "cv",
  number = 5,
  classProbs = TRUE,
  summaryFunction = twoClassSummary,
  savePredictions = "final"
)

msg("\n=== Training Logistic Regression (5-fold CV) on 80% split ===")
logreg_cv <- train(
  diagnosed_diabetes ~ .,
  data = trn_x,
  method = "glm",
  family = "binomial",
  metric = "ROC",
  trControl = ctrl
)

msg("\n=== CV Results (on 80% split, 5-fold) ===")
print(logreg_cv)

# Validate on held-out 20%
msg("\n=== Evaluating on held-out 20% validation set ===")
val_prob <- predict(logreg_cv, val_x, type="prob")[,"yes"]
val_pred <- ifelse(val_prob >= 0.5, "yes", "no") %>% factor(levels=c("no","yes"))

cm <- confusionMatrix(val_pred, val$diagnosed_diabetes, positive="yes")
auc <- as.numeric(pROC::auc(pROC::roc(response=val$diagnosed_diabetes, predictor=val_prob, levels=c("no","yes"), direction="<")))

msg("\nConfusion Matrix (20% holdout):")
print(cm)
msg("\nHoldout AUC: ", sprintf("%.5f", auc))
msg("Holdout Accuracy: ", sprintf("%.5f", cm$overall[["Accuracy"]]))

# Retrain on 100% of train data (no CV) for final submission
msg("\n=== Retraining Logistic Regression on 100% of training data ===")
full_x <- train %>% select(-id)
test_x <- test %>% select(-id)

final_ctrl <- trainControl(method="none", classProbs=TRUE)

logreg_final <- train(
  diagnosed_diabetes ~ .,
  data = full_x,
  method = "glm",
  family = "binomial",
  trControl = final_ctrl
)

# Predict probabilities for submission
test_prob <- predict(logreg_final, test_x, type="prob")[,"yes"]

submission <- tibble(
  !!id_col := test$id,
  !!target_col := test_prob
)

out_path <- "data/processed/submission/submission-logistic_regression-5-fold.csv"
write_csv(submission, out_path)

msg("\n=== SUBMISSION SAVED ===")
msg(out_path)
msg("\nPreview:")
print(head(submission, 10), n=10)
