import os
import pandas as pd
import numpy as np
import importlib
from training.compare_models import compare_all_models
from visualization.plotting_engine import save_model_visuals
from visualization.dashboard import generate_html_report
from io.submission_writer import write_kaggle_submission

def run_all_and_report():
    print("Loading preprocessed data...")
    df = pd.read_parquet("data/processed/train.parquet")
    test_df = pd.read_csv("data/raw/test.csv")
    test_ids = test_df['id'].tolist()
    
    y = df['smoking'].values
    X = df.drop(columns=['smoking']).values
    X_test = test_df.drop(columns=['id']).values

    output_viz = "data/processed/visualizations"
    output_subs = "data/processed/submissions"
    os.makedirs(output_viz, exist_ok=True)
    os.makedirs(output_subs, exist_ok=True)

    # 1. Compare and Save Individual Metrics/Visuals
    comparison_df = compare_all_models(X, y)
    
    # 2. Final Training and Submissions for all 11
    for _, row in comparison_df.iterrows():
        name = row['model']
        print(f"Finalizing {name}...")
        
        module = importlib.import_module(f"models.{name}")
        model = module.get_model()
        model.fit(X, y)
        
        # Generate Probabilities for Test set
        test_probs = model.predict_proba(X_test)[:, 1]
        write_kaggle_submission(test_ids, test_probs, f"{output_subs}/{name}_submission.csv")
        
    # 3. Save Dashboard
    generate_html_report(comparison_df, "data/processed/model_report.html")
    print("Full run complete. Check data/processed/ for report and submissions.")

if __name__ == "__main__":
    run_all_and_report()
