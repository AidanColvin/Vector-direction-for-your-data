import os
import sys
import pandas as pd
import numpy as np
import importlib

# Add script directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from training.compare_models import compare_all_models
from training.blender import blend_submissions
from visualization.dashboard import generate_html_report
from file_io.submission_writer import write_kaggle_submission

def run_all_and_report():
    print("🚀 Starting BioBeat ML Pipeline...")
    parquet_path = "data/processed/train.parquet"
    output_subs = "data/processed/submissions"
    os.makedirs(output_subs, exist_ok=True)

    df = pd.read_parquet(parquet_path)
    test_df = pd.read_csv("data/raw/test.csv")
    test_ids = test_df['id'].tolist()
    
    y = df['smoking'].values
    X = df.drop(columns=['smoking']).values
    X_test = test_df.drop(columns=['id']).values

    # 1. Run 5-Fold CV on all 11 models
    comparison_df = compare_all_models(X, y)
    
    # 2. Final Training & Individual Submissions
    for _, row in comparison_df.iterrows():
        name = row['model']
        print(f"Finalizing {name}...")
        module = importlib.import_module(f"models.{name}")
        model_func = getattr(module, 'get_model', None) or getattr(module, 'get_xgboost_classifier')
        model = model_func()
        model.fit(X, y)
        
        test_probs = model.predict_proba(X_test)[:, 1]
        write_kaggle_submission(test_ids, test_probs, f"{output_subs}/{name}_submission.csv")

    # 3. Create Blended Submission (The Winner)
    blend_submissions(output_subs, f"{output_subs}/blended_final_submission.csv")
    
    # 4. Save Final Dashboard
    generate_html_report(comparison_df, "data/processed/model_report.html")
    print("✅ Pipeline Success. Results in data/processed/model_report.html")

if __name__ == "__main__":
    run_all_and_report()
