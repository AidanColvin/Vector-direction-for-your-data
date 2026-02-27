import os
import pandas as pd
import numpy as np
import importlib
from training.compare_models import compare_all_models
from visualization.plotting_engine import save_model_visuals
from visualization.dashboard import generate_html_report
from io.submission_writer import write_kaggle_submission
from evaluation.importance import get_feature_importance
from tuning.optimizer import tune_hyperparameters

def run_all_and_report():
    print("🚀 Starting BioBeat ML Pipeline...")
    
    # Check for data
    parquet_path = "data/processed/train.parquet"
    if not os.path.exists(parquet_path):
        print(f"❌ Error: {parquet_path} not found. Run preprocessing first.")
        return

    df = pd.read_parquet(parquet_path)
    test_df = pd.read_csv("data/raw/test.csv")
    test_ids = test_df['id'].tolist()
    
    # Separate features and target
    y = df['smoking'].values
    X = df.drop(columns=['smoking']).values
    feature_names = df.drop(columns=['smoking']).columns.tolist()
    X_test = test_df.drop(columns=['id']).values

    output_viz = "data/processed/visualizations"
    output_subs = "data/processed/submissions"
    os.makedirs(output_viz, exist_ok=True)
    os.makedirs(output_subs, exist_ok=True)

    # 1. Evaluate all 11 models to find the baseline leader
    print("📊 Evaluating 11 models via 5-fold CV...")
    comparison_df = compare_all_models(X, y)
    
    # 2. Final Training, Tuning, and Submissions
    for _, row in comparison_df.iterrows():
        name = row['model']
        print(f"🛠 Finalizing {name}...")
        
        module = importlib.import_module(f"models.{name}")
        model_func = getattr(module, 'get_model', None) or getattr(module, 'get_xgboost_classifier')
        model = model_func()

        # Fit and extract insights
        model.fit(X, y)
        
        # Save Visuals (Importance & ROC/CM)
        get_feature_importance(model, feature_names, name, output_viz)
        
        # Generate Submissions
        test_probs = model.predict_proba(X_test)[:, 1]
        write_kaggle_submission(test_ids, test_probs, f"{output_subs}/{name}_submission.csv")
        
    # 3. Save Final Dashboard
    generate_html_report(comparison_df, "data/processed/model_report.html")
    print("✅ Full run complete. View results in data/processed/model_report.html")

if __name__ == "__main__":
    run_all_and_report()
