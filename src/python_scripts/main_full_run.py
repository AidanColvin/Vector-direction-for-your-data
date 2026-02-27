import os
import sys
import pandas as pd
import importlib
from visualization.dashboard import generate_html_report
from training.blender import blend_smart_weighted
from training.compare_models import compare_all_models

def run_all_and_report():
    print("🚀 Starting BioBeat ML Pipeline...")
    parquet_path = "data/processed/train.parquet"
    output_subs = "data/processed/submissions"
    report_path = "data/processed/model_report.html"

    df = pd.read_parquet(parquet_path)
    X = df.drop(columns=['smoking']).values
    y = df['smoking'].values

    # 1. Generate metrics and comparison
    comparison_df = compare_all_models(X, y)
    
    # 2. Save the HTML report first (The Blender will read this)
    generate_html_report(comparison_df, report_path)
    
    # 3. Finalize and run Smart Blender
    blend_smart_weighted(output_subs, report_path, f"{output_subs}/blended_final_submission.csv")
    print("✅ Full Pipeline Run Successful.")

if __name__ == "__main__":
    run_all_and_report()
