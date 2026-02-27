library(caret)

get_cross_validation <- function(num_folds = 5) {
  # """
  # given the number of folds
  # return a caret trainControl object for cross-validation
  # 5 folds mathematically creates an 80/20 train/test split
  # """
  control <- trainControl(
    method = "cv",
    number = num_folds,
    classProbs = TRUE,
    summaryFunction = twoClassSummary,
    savePredictions = "final"
  )
  return(control)
}
