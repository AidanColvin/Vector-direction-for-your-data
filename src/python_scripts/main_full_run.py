import os
import sys
import pandas as pd
import numpy as np
import importlib

# Add script directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from training.compare_models import compare_all_models
from visualization.plotting_engine import save_model_visuals
from visualization.dashboard import generate_html_report
from file_io.submission_writer import write_kaggle_submission
from evaluation.importance import get_feature_importance

def run_all_and_report():
    print("🚀 Starting BioBeat ML Pipeline...")
    parquet_path = "data/processed/train.parquet"
    
    # Auto-convert if parquet doesn't exist yet
    if not os.path.exists(parquet_path):
        from file_io.csv_to_parquet import convert_to_parquet
        convert_to_parquet("data/processed/train_standardized_cpp.csv", parquet_path)

    df = pd.read_parquet(parquet_path)
    test_df = pd.read_csv("data/raw/test.csv")
    
    y = df['smoking'].values
    X = df.drop(columns=['smoking']).values
    feature_names = df.drop(columns=['smoking']).columns.tolist()
    
    comparison_df = compare_all_models(X, y)
    generate_html_report(comparison_df, "data/processed/model_report.html")
    print("✅ Pipeline Success. Results in data/processed/model_report.html")

if __name__ == "__main__":
    run_all_and_report()
