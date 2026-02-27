import pandas as pd
import os
from io.csv_to_parquet import convert_to_parquet
from training.compare_models import compare_all_models
from generate_submission import create_submission
import importlib

def main():
    # 1. Convert to Parquet for speed
    convert_to_parquet("data/processed/train_standardized_cpp.csv", "data/processed/train.parquet")
    
    # 2. Load and Prepare
    df = pd.read_parquet("data/processed/train.parquet")
    y = df['smoking'].values # Assuming 'smoking' is the target
    X = df.drop(columns=['smoking']).values
    
    # 3. Compare Models
    comparison_df = compare_all_models(X, y)
    print("\n--- Model Comparison Table ---")
    print(comparison_df)
    
    # 4. Train best model on 100% data
    best_model_name = comparison_df.iloc[0]['model']
    print(f"\nWinner: {best_model_name}. Training final model...")
    
    best_mod = importlib.import_module(f"models.{best_model_name}")
    final_model = best_mod.get_model() if hasattr(best_mod, 'get_model') else best_mod.get_xgboost_classifier()
    final_model.fit(X, y)
    
    # 5. Generate Submission
    create_submission(final_model, "data/raw/test.csv", "data/processed/submission.csv")

if __name__ == "__main__":
    main()
