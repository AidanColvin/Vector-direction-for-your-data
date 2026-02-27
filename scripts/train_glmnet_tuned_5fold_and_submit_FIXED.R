options(warn=1)
msg <- function(...) cat(..., "\n", sep="")
die <- function(...) { msg("ERROR: ", ...); quit(status=1) }

req <- c("readr","dplyr","caret","glmnet","pROC","tibble")
missing <- req[!req %in% rownames(installed.packages())]
if (length(missing)) install.packages(missing, repos="https://cloud.r-project.org")

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(caret); library(glmnet); library(pROC); library(tibble)
})

set.seed(42)

train_path  <- "data/processed/train_standardized.csv"
test_path   <- "data/processed/test_standardized.csv"
sample_path <- "data/raw/sample_submission.csv"

if (!file.exists(train_path))  die("Missing ", train_path)
if (!file.exists(test_path))   die("Missing ", test_path)
if (!file.exists(sample_path)) die("Missing ", sample_path)

train <- read_csv(train_path, show_col_types=FALSE)
test  <- read_csv(test_path,  show_col_types=FALSE)
sample <- read_csv(sample_path, show_col_types=FALSE)

id_col <- names(sample)[1]
target_col <- names(sample)[2]

if (!("id" %in% names(train))) die("train missing id")
if (!("diagnosed_diabetes" %in% names(train))) die("train missing diagnosed_diabetes")
if (!("id" %in% names(test)))  die("test missing id")

train <- train %>%
  mutate(diagnosed_diabetes = factor(ifelse(diagnosed_diabetes == 1, "yes", "no"), levels=c("no","yes")))

# 80/20 split (for reporting only)
idx <- createDataPartition(train$diagnosed_diabetes, p=0.80, list=FALSE)
trn <- train[idx, ]
val <- train[-idx, ]

# Build predictors-only frames
trn_Xdf <- trn %>% select(-id, -diagnosed_diabetes)
val_Xdf <- val %>% select(-id, -diagnosed_diabetes)

# dummyVars on predictors only (so it works on test)
dv <- dummyVars(~ ., data=trn_Xdf, fullRank=TRUE)
X_trn <- predict(dv, trn_Xdf)
X_val <- predict(dv, val_Xdf)

y_trn <- trn$diagnosed_diabetes
y_val <- val$diagnosed_diabetes

ctrl <- trainControl(
  method="cv",
  number=5,
  classProbs=TRUE,
  summaryFunction=twoClassSummary
)

grid <- expand.grid(
  alpha = c(0, 0.25, 0.5, 0.75, 1),
  lambda = 10^seq(-4, 1, length.out=40)
)

msg("\n=== Training GLMNET (elastic net) 5-fold CV on 80% split ===")
fit <- train(
  x = X_trn, y = y_trn,
  method="glmnet",
  metric="ROC",
  trControl=ctrl,
  tuneGrid=grid
)

msg("\nBest tuned params:")
print(fit$bestTune)

# Holdout AUC
val_prob <- predict(fit, X_val, type="prob")[,"yes"]
auc <- as.numeric(pROC::auc(pROC::roc(y_val, val_prob, levels=c("no","yes"), direction="<")))
msg("\nHoldout AUC: ", sprintf("%.5f", auc))

# Refit on 100% train with bestTune
msg("\n=== Retraining on 100% train with bestTune ===")
full_Xdf <- train %>% select(-id, -diagnosed_diabetes)
dv_full <- dummyVars(~ ., data=full_Xdf, fullRank=TRUE)
X_full <- predict(dv_full, full_Xdf)
y_full <- train$diagnosed_diabetes

final <- train(
  x = X_full, y = y_full,
  method="glmnet",
  trControl=trainControl(method="none", classProbs=TRUE),
  tuneGrid=fit$bestTune
)

# Predict on test
test_Xdf <- test %>% select(-id)
X_test <- predict(dv_full, test_Xdf)
test_prob <- predict(final, X_test, type="prob")[,"yes"]

submission <- tibble(
  !!id_col := test$id,
  !!target_col := test_prob
)

out_path <- "data/processed/submission/submission-glmnet-tuned-5fold.csv"
write_csv(submission, out_path)

msg("\n=== SUBMISSION SAVED ===")
msg(out_path)
