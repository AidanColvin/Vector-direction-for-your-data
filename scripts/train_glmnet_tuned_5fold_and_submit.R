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

# 80/20 split for a real holdout check (optional but useful)
idx <- createDataPartition(train$diagnosed_diabetes, p=0.80, list=FALSE)
trn <- train[idx, ] %>% select(-id)
val <- train[-idx, ] %>% select(-id)

# glmnet needs dummyVars (but your encoded data is already numeric; still safe)
dv <- dummyVars(diagnosed_diabetes ~ ., data=trn, fullRank=TRUE)
X_trn <- predict(dv, trn)
y_trn <- trn$diagnosed_diabetes

X_val <- predict(dv, val)
y_val <- val$diagnosed_diabetes

ctrl <- trainControl(
  method="cv",
  number=5,
  classProbs=TRUE,
  summaryFunction=twoClassSummary
)

# Tune alpha (elastic-net mix). caret will tune lambda automatically within glmnet grid.
grid <- expand.grid(
  alpha = c(0, 0.25, 0.5, 0.75, 1),
  lambda = 10^seq(-4, 1, length.out=40)
)

msg("\n=== Training GLMNET (elastic net) with 5-fold CV on 80% split ===")
fit <- train(
  x = X_trn,
  y = y_trn,
  method = "glmnet",
  metric = "ROC",
  trControl = ctrl,
  tuneGrid = grid
)

msg("\nBest tuned params:")
print(fit$bestTune)
msg("\nCV summary (top rows):")
print(head(fit$results[order(-fit$results$ROC), ], 10))

# Holdout evaluation
val_prob <- predict(fit, X_val, type="prob")[,"yes"]
auc <- as.numeric(pROC::auc(pROC::roc(y_val, val_prob, levels=c("no","yes"), direction="<")))
msg("\nHoldout AUC: ", sprintf("%.5f", auc))

# Refit on 100% train using bestTune
msg("\n=== Retraining on 100% training data with bestTune ===")
full <- train %>% select(-id)
dv_full <- dummyVars(diagnosed_diabetes ~ ., data=full, fullRank=TRUE)
X_full <- predict(dv_full, full)
y_full <- full$diagnosed_diabetes

final_ctrl <- trainControl(method="none", classProbs=TRUE)
final <- train(
  x = X_full,
  y = y_full,
  method="glmnet",
  trControl=final_ctrl,
  tuneGrid=fit$bestTune
)

# Predict on test
X_test <- predict(dv_full, test %>% select(-id))
test_prob <- predict(final, X_test, type="prob")[,"yes"]

submission <- tibble(
  !!id_col := test$id,
  !!target_col := test_prob
)

out_path <- "data/processed/submission/submission-glmnet-tuned-5fold.csv"
write_csv(submission, out_path)

msg("\n=== SUBMISSION SAVED ===")
msg(out_path)
