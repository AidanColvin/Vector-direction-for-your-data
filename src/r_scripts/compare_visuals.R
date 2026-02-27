library(ggplot2)
library(dplyr)
library(tidyr)

# given a path to the master_scorecard.csv
# return a horizontal bar chart of AUC scores
# formatted for academic publication
generate_auc_plot <- function(csv_path, output_path) {
  if (!file.exists(csv_path)) return(NULL)
  
  data <- read.csv(csv_path)
  
  p <- ggplot(data, aes(x = reorder(model, auc), y = auc, fill = auc)) +
    geom_bar(stat = "identity") +
    coord_flip() +
    theme_minimal() +
    labs(title = "BioBeat Model Comparison",
         subtitle = "Comparison of 11 Supervised and Deep Learning Models",
         x = "Model Architecture",
         y = "Area Under the ROC Curve (AUC)") +
    scale_fill_gradient(low = "#c3d9ff", high = "#276DC3")
    
  ggsave(output_path, plot = p, width = 10, height = 6)
}

# Main execution
args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 2) {
  generate_auc_plot(args[1], args[2])
}
