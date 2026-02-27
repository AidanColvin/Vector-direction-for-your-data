# compare_all_models.R
# Generates all cross-model comparison visualisations
# Saves outputs to data/processed/visualizations/comparison/

library(ggplot2)
library(pROC)

OUT <- "data/processed/visualizations/comparison"

plot_roc_overlay <- function(results_list, out_path) {
  #' given a named list where each element has actuals and predicted_probs
  #' saves an overlaid ROC curve PNG with one line per model to out_path
  #' legend shows each model name and its AUC
  all_roc <- data.frame()
  for (model_name in names(results_list)) {
    r       <- results_list[[model_name]]
    roc_obj <- roc(r$actuals, r$predicted_probs, quiet = TRUE)
    auc_val <- round(auc(roc_obj), 3)
    roc_df  <- data.frame(
      fpr   = 1 - roc_obj$specificities,
      tpr   = roc_obj$sensitivities,
      model = paste0(model_name, " (AUC=", auc_val, ")")
    )
    all_roc <- rbind(all_roc, roc_df)
  }
  p <- ggplot(all_roc, aes(x = fpr, y = tpr, colour = model)) +
    geom_line(linewidth = 1) +
    geom_abline(linetype = "dashed", colour = "grey60") +
    labs(title = "ROC Curve Comparison — All Models",
         x = "False Positive Rate", y = "True Positive Rate", colour = "Model") +
    theme_minimal()
  ggsave(out_path, p, width = 9, height = 6)
}

plot_auc_bar_chart <- function(results_list, out_path) {
  #' given a named list where each element has actuals and predicted_probs
  #' saves a bar chart of AUC scores per model PNG to out_path
  #' bars sorted highest to lowest
  auc_df <- data.frame(
    model = names(results_list),
    auc   = sapply(results_list, function(r) {
      round(auc(roc(r$actuals, r$predicted_probs, quiet = TRUE)), 3)
    })
  )
  p <- ggplot(auc_df, aes(x = reorder(model, auc), y = auc, fill = model)) +
    geom_col(show.legend = FALSE) +
    geom_text(aes(label = auc), hjust = -0.1, size = 3.5) +
    coord_flip() +
    ylim(0, 1.05) +
    labs(title = "AUC Score Comparison — All Models",
         x = NULL, y = "AUC") +
    theme_minimal()
  ggsave(out_path, p, width = 8, height = 5)
}

plot_metrics_bar_chart <- function(scorecard_df, metric, out_path) {
  #' given a scorecard data frame with cols model and one metric column
  #' and a metric name string and an output path
  #' saves a bar chart comparing all models on that metric PNG to out_path
  p <- ggplot(scorecard_df, aes(x = reorder(model, .data[[metric]]),
                                 y = .data[[metric]], fill = model)) +
    geom_col(show.legend = FALSE) +
    geom_text(aes(label = round(.data[[metric]], 3)), hjust = -0.1, size = 3.5) +
    coord_flip() +
    ylim(0, 1.1) +
    labs(title = paste(metric, "Comparison — All Models"),
         x = NULL, y = metric) +
    theme_minimal()
  safe_metric <- gsub("[^a-zA-Z0-9_]", "_", tolower(metric))
  ggsave(out_path, p, width = 8, height = 5)
}

plot_confusion_matrix_grid <- function(results_list, out_path) {
  #' given a named list where each element has actuals and predictions
  #' saves a grid of all confusion matrices as a single PNG to out_path
  #' one panel per model for side by side pattern spotting
  all_cm <- data.frame()
  for (model_name in names(results_list)) {
    r  <- results_list[[model_name]]
    cm <- as.data.frame(table(Actual = r$actuals, Predicted = r$predictions))
    cm$model <- model_name
    all_cm <- rbind(all_cm, cm)
  }
  p <- ggplot(all_cm, aes(x = Predicted, y = Actual, fill = Freq)) +
    geom_tile() +
    geom_text(aes(label = Freq), colour = "white", size = 3.5) +
    scale_fill_gradient(low = "#90CAF9", high = "#1565C0") +
    facet_wrap(~model, ncol = 3) +
    labs(title = "Confusion Matrix Grid — All Models") +
    theme_minimal()
  ggsave(out_path, p, width = 14, height = 10)
}

plot_precision_recall_overlay <- function(results_list, out_path) {
  #' given a named list where each element has actuals and predicted_probs
  #' saves an overlaid precision-recall curve PNG to out_path
  #' more informative than ROC for imbalanced diabetes data
  all_pr <- data.frame()
  for (model_name in names(results_list)) {
    r       <- results_list[[model_name]]
    roc_obj <- roc(r$actuals, r$predicted_probs, quiet = TRUE)
    pr_df   <- data.frame(
      recall    = roc_obj$sensitivities,
      precision = roc_obj$precisions,
      model     = model_name
    )
    all_pr <- rbind(all_pr, pr_df)
  }
  p <- ggplot(all_pr, aes(x = recall, y = precision, colour = model)) +
    geom_line(linewidth = 1) +
    labs(title = "Precision-Recall Curve Comparison — All Models",
         x = "Recall", y = "Precision", colour = "Model") +
    theme_minimal()
  ggsave(out_path, p, width = 9, height = 6)
}

plot_metric_dot_plot <- function(scorecard_df, out_path) {
  #' given a scorecard data frame with cols model, AUC, F1, Precision, Recall, Accuracy
  #' saves a dot plot comparing all models across all metrics PNG to out_path
  #' each dot is one model, axis is metric value
  long_df <- tidyr::pivot_longer(scorecard_df, cols = -model,
                                  names_to = "metric", values_to = "value")
  p <- ggplot(long_df, aes(x = value, y = model, colour = metric)) +
    geom_point(size = 4) +
    facet_wrap(~metric, scales = "free_x") +
    labs(title = "Metric Dot Plot — All Models",
         x = "Value", y = NULL) +
    theme_minimal() +
    theme(legend.position = "none")
  ggsave(out_path, p, width = 12, height = 6)
}

plot_calibration_overlay <- function(results_list, out_path, bins = 10) {
  #' given a named list where each element has actuals and predicted_probs
  #' saves an overlaid calibration curve PNG to out_path
  #' shows which model probabilities are most trustworthy
  all_cal <- data.frame()
  for (model_name in names(results_list)) {
    r      <- results_list[[model_name]]
    df     <- data.frame(prob = r$predicted_probs, actual = as.numeric(r$actuals) - 1)
    df$bin <- cut(df$prob, breaks = bins, include.lowest = TRUE)
    cal    <- aggregate(cbind(prob, actual) ~ bin, data = df, FUN = mean)
    cal$model <- model_name
    all_cal <- rbind(all_cal, cal)
  }
  p <- ggplot(all_cal, aes(x = prob, y = actual, colour = model)) +
    geom_point(size = 2) +
    geom_line() +
    geom_abline(linetype = "dashed", colour = "grey60") +
    labs(title = "Calibration Curve Comparison — All Models",
         x = "Mean Predicted Probability", y = "Fraction Positive", colour = "Model") +
    theme_minimal()
  ggsave(out_path, p, width = 9, height = 6)
}

plot_train_vs_test_error <- function(scorecard_df, out_path) {
  #' given a scorecard data frame with cols model, train_error, test_error
  #' saves a grouped bar chart PNG to out_path
  #' highlights overfitting where train error is much lower than test error
  long_df <- tidyr::pivot_longer(scorecard_df[, c("model","train_error","test_error")],
                                  cols = -model,
                                  names_to = "split", values_to = "error")
  p <- ggplot(long_df, aes(x = model, y = error, fill = split)) +
    geom_col(position = "dodge") +
    scale_fill_manual(values = c("train_error" = "#42A5F5", "test_error" = "#EF5350")) +
    coord_flip() +
    labs(title = "Train vs Test Error — All Models",
         x = NULL, y = "Error", fill = NULL) +
    theme_minimal()
  ggsave(out_path, p, width = 9, height = 5)
}

save_master_scorecard <- function(scorecard_df, out_path) {
  #' given a scorecard data frame with one row per model
  #' saves a CSV master scorecard to out_path
  #' columns: model, AUC, F1, Precision, Recall, Accuracy
  write.csv(scorecard_df, out_path, row.names = FALSE)
}

run_all_comparisons <- function(results_list, scorecard_df) {
  #' given a named results list and a scorecard data frame
  #' saves all cross-model comparison visualisations to data/processed/visualizations/comparison/
  #' call this after all individual model runners have been called

  plot_roc_overlay(results_list,
    file.path(OUT, "comparison_roc_overlay_all_models.png"))

  plot_auc_bar_chart(results_list,
    file.path(OUT, "comparison_auc_bar_chart_all_models.png"))

  plot_metrics_bar_chart(scorecard_df, "F1",
    file.path(OUT, "comparison_f1_bar_chart_all_models.png"))

  plot_metrics_bar_chart(scorecard_df, "Accuracy",
    file.path(OUT, "comparison_accuracy_bar_chart_all_models.png"))

  plot_metrics_bar_chart(scorecard_df, "Recall",
    file.path(OUT, "comparison_recall_bar_chart_all_models.png"))

  plot_confusion_matrix_grid(results_list,
    file.path(OUT, "comparison_confusion_matrix_grid_all_models.png"))

  plot_precision_recall_overlay(results_list,
    file.path(OUT, "comparison_precision_recall_overlay_all_models.png"))

  plot_metric_dot_plot(scorecard_df,
    file.path(OUT, "comparison_metric_dot_plot_all_models.png"))

  plot_calibration_overlay(results_list,
    file.path(OUT, "comparison_calibration_overlay_all_models.png"))

  plot_train_vs_test_error(scorecard_df,
    file.path(OUT, "comparison_train_vs_test_error_all_models.png"))

  save_master_scorecard(scorecard_df,
    file.path(OUT, "comparison_master_scorecard_all_models.csv"))

  cat("All comparison visualisations saved to", OUT, "\n")
}
