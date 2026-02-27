import pandas as pd
import numpy as np
import importlib
from typing import Dict
from training.cross_validation import run_5_fold_cv
from evaluation.metrics import get_classification_metrics

def compare_all_models(X: np.ndarray, y: np.ndarray) -> pd.DataFrame:
    """
    given feature matrix and target
    iterates through all 7 model modules
    returns a dataframe comparing mean metrics
    """
    model_modules = [
        "models.xgboost_model", "models.logistic_model", "models.rf_model",
        "models.nb_model", "models.svm_model", "models.gbm_model", "models.linear_model"
    ]
    
    results = []
    
    for module_name in model_modules:
        print(f"Evaluating {module_name}...")
        module = importlib.import_module(module_name)
        model = module.get_model() if hasattr(module, 'get_model') else module.get_xgboost_classifier()
        
        cv_results = run_5_fold_cv(model, X, y)
        
        fold_metrics = []
        for y_val, y_prob in cv_results:
            y_pred = (y_prob >= 0.5).astype(int)
            fold_metrics.append(get_classification_metrics(y_val, y_pred, y_prob))
            
        # Aggregate means
        mean_metrics = pd.DataFrame(fold_metrics).mean().to_dict()
        mean_metrics["model"] = module_name.split('.')[-1]
        results.append(mean_metrics)
        
    return pd.DataFrame(results).sort_values(by="auc", ascending=False)
