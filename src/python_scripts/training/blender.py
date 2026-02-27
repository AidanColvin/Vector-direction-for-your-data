import pandas as pd
import os
from typing import Dict

def blend_weighted_submissions(submission_dir: str, output_path: str, weights: Dict[str, float] = None):
    """
    given submission directory and optional weights
    calculates a weighted average of probabilities
    if no weights provided, defaults to equal averaging
    """
    sub_files = [f for f in os.listdir(submission_dir) if f.endswith('.csv') and 'blended' not in f]
    
    if not sub_files:
        print("No submissions found.")
        return

    print(f"Blending {len(sub_files)} models with weights...")
    blended_df = None
    total_weight = 0.0

    for file in sub_files:
        model_name = file.replace('_submission.csv', '')
        weight = weights.get(model_name, 1.0) if weights else 1.0
        
        df = pd.read_csv(os.path.join(submission_dir, file))
        
        if blended_df is None:
            blended_df = df.copy()
            blended_df['smoking'] = df['smoking'] * weight
        else:
            blended_df['smoking'] += df['smoking'] * weight
        
        total_weight += weight

    blended_df['smoking'] /= total_weight
    blended_df.to_csv(output_path, index=False)
    print(f"✅ Weighted Blender complete: {output_path}")

if __name__ == "__main__":
    # Example: Giving XGBoost and TabNet more weight
    custom_weights = {
        "xgboost_model": 2.0,
        "tabnet_model": 1.5,
        "transformer_model": 1.5
    }
    blend_weighted_submissions("data/processed/submissions", "data/processed/submissions/blended_final.csv", custom_weights)
