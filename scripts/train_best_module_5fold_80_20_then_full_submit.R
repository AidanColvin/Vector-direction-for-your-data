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

# 80/20 split
idx <- createDataPartition(train$diagnosed_diabetes, p=0.80, list=FALSE)
trn <- train[idx, ]
val <- train[-idx, ]

ctrl <- trainControl(
  method="cv",
  number=5,
  classProbs=TRUE,
  summaryFunction=twoClassSummary,
  savePredictions="final"
)

scoreboard <- list()

# ----------------------------
# Model A: Logistic Regression (glm)
# ----------------------------
msg("\n=== CV: logistic_regression (glm) ===")
glm_fit <- train(
  diagnosed_diabetes ~ .,
  data = trn %>% select(-id),
  method = "glm",
  family = "binomial",
  metric = "ROC",
  trControl = ctrl
)

# holdout AUC
glm_val_prob <- predict(glm_fit, val %>% select(-id), type="prob")[,"yes"]
glm_auc <- as.numeric(pROC::auc(pROC::roc(val$diagnosed_diabetes, glm_val_prob, levels=c("no","yes"), direction="<")))
glm_acc <- mean((glm_val_prob >= 0.5) == (val$diagnosed_diabetes == "yes"))

scoreboard[["logistic_regression"]] <- list(
  name="logistic_regression",
  cvROC=max(glm_fit$results$ROC, na.rm=TRUE),
  holdoutAUC=glm_auc,
  holdoutAcc=glm_acc,
  obj=glm_fit,
  type="caret_glm"
)

# ----------------------------
# Model B: GLMNET (elastic net)
# ----------------------------
msg("\n=== CV: glmnet (elastic net) ===")
trn_Xdf <- trn %>% select(-id, -diagnosed_diabetes)
val_Xdf <- val %>% select(-id, -diagnosed_diabetes)

dv <- dummyVars(~ ., data=trn_Xdf, fullRank=TRUE)
X_trn <- predict(dv, trn_Xdf)
X_val <- predict(dv, val_Xdf)

grid <- expand.grid(
  alpha = c(0, 0.25, 0.5, 0.75, 1),
  lambda = 10^seq(-4, 1, length.out=40)
)

glmnet_fit <- train(
  x = X_trn,
  y = trn$diagnosed_diabetes,
  method="glmnet",
  metric="ROC",
  trControl=ctrl,
  tuneGrid=grid
)

glmnet_val_prob <- predict(glmnet_fit, X_val, type="prob")[,"yes"]
glmnet_auc <- as.numeric(pROC::auc(pROC::roc(val$diagnosed_diabetes, glmnet_val_prob, levels=c("no","yes"), direction="<")))
glmnet_acc <- mean((glmnet_val_prob >= 0.5) == (val$diagnosed_diabetes == "yes"))

scoreboard[["glmnet"]] <- list(
  name="glmnet",
  cvROC=max(glmnet_fit$results$ROC, na.rm=TRUE),
  holdoutAUC=glmnet_auc,
  holdoutAcc=glmnet_acc,
  obj=glmnet_fit,
  dv=dv,
  bestTune=glmnet_fit$bestTune,
  type="caret_glmnet"
)

# ----------------------------
# Pick best model
# Prefer CV ROC, tie-break by holdout AUC then holdout Acc
# ----------------------------
sc <- tibble(
  model = c(scoreboard$logistic_regression$name, scoreboard$glmnet$name),
  cvROC = c(scoreboard$logistic_regression$cvROC, scoreboard$glmnet$cvROC),
  holdoutAUC = c(scoreboard$logistic_regression$holdoutAUC, scoreboard$glmnet$holdoutAUC),
  holdoutAcc = c(scoreboard$logistic_regression$holdoutAcc, scoreboard$glmnet$holdoutAcc)
) %>% arrange(desc(cvROC), desc(holdoutAUC), desc(holdoutAcc))

msg("\n=== SCOREBOARD ===")
print(sc)

best_name <- sc$model[1]
msg("\n=== BEST MODEL SELECTED ===")
msg(best_name)

# ----------------------------
# Retrain best model on 100% train and submit
# ----------------------------
out1_dir <- "data/processed/submission"
out2_dir <- "data/prossed/submissions"
dir.create(out1_dir, recursive=TRUE, showWarnings=FALSE)
dir.create(out2_dir, recursive=TRUE, showWarnings=FALSE)

if (best_name == "logistic_regression") {

  final <- train(
    diagnosed_diabetes ~ .,
    data = train %>% select(-id),
    method="glm",
    family="binomial",
    trControl=trainControl(method="none", classProbs=TRUE)
  )

  test_prob <- predict(final, test %>% select(-id), type="prob")[,"yes"]

} else if (best_name == "glmnet") {

  full_Xdf <- train %>% select(-id, -diagnosed_diabetes)
  dv_full <- dummyVars(~ ., data=full_Xdf, fullRank=TRUE)
  X_full <- predict(dv_full, full_Xdf)
  y_full <- train$diagnosed_diabetes

  final <- train(
    x = X_full,
    y = y_full,
    method="glmnet",
    trControl=trainControl(method="none", classProbs=TRUE),
    tuneGrid=scoreboard$glmnet$bestTune
  )

  X_test <- predict(dv_full, test %>% select(-id))
  test_prob <- predict(final, X_test, type="prob")[,"yes"]

} else {
  die("Unexpected best model: ", best_name)
}

submission <- tibble(
  !!id_col := test$id,
  !!target_col := test_prob
)

out1 <- file.path(out1_dir, paste0("submission-", best_name, ".csv"))
out2 <- file.path(out2_dir, paste0("submission-", best_name, ".csv"))
write_csv(submission, out1)
write_csv(submission, out2)

msg("\n=== SUBMISSION SAVED ===")
msg(out1)
msg(out2)

# record model used
writeLines(best_name, file.path(out1_dir, "BEST_MODEL_USED.txt"))
writeLines(best_name, file.path(out2_dir, "BEST_MODEL_USED.txt"))
