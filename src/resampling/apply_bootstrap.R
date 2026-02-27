library(caret)

get_bootstrap <- function(num_resamples = 25) {
  # """
  # given the number of resamples
  # return a caret trainControl object for bootstrapping
  # uses random sampling with replacement
  # """
  control <- trainControl(
    method = "boot",
    number = num_resamples,
    classProbs = TRUE,
    summaryFunction = twoClassSummary
  )
  return(control)
}
