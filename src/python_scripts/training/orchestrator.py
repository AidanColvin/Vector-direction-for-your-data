import pandas as pd
import numpy as np
import os
import sys

# Add root to path for modular imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.xgboost_model import get_xgboost_classifier
from training.cross_validation import run_5_fold_cv
from evaluation.metrics import get_classification_metrics

def train_and_evaluate(train_parquet_path: str, target_col: str):
    """
    given parquet path and target column name
    run 5-fold stratified cv
    output aggregated metrics
    return fully trained model on entire dataset
    """
    df = pd.read_parquet(train_parquet_path)
    X = df.drop(columns=[target_col]).values
    y = df[target_col].values

    model = get_xgboost_classifier()
    print(f"Starting 5-fold Cross-Validation...")
    
    cv_results = run_5_fold_cv(model, X, y)
    
    all_metrics = []
    for y_val, y_prob in cv_results:
        y_pred = (y_prob >= 0.5).astype(int)
        metrics = get_classification_metrics(y_val, y_pred, y_prob)
        all_metrics.append(metrics)

    # Average metrics
    avg_auc = np.mean([m['auc'] for m in all_metrics])
    avg_acc = np.mean([m['accuracy'] for m in all_metrics])
    
    print(f"CV Results -> Avg AUC: {avg_auc:.4f}, Avg Accuracy: {avg_acc:.4f}")

    # Refit on 100% of data for the final submission
    print("Refitting on full training set...")
    model.fit(X, y)
    return model
