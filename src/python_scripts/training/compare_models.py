import pandas as pd
import numpy as np
import importlib
from training.cross_validation import run_5_fold_cv
from evaluation.metrics import get_classification_metrics

def compare_all_models(X: np.ndarray, y: np.ndarray) -> pd.DataFrame:
    """
    compares 7 supervised models + 2 advanced models (Deep Learning & Pattern Rec)
    returns a ranked table by AUC accuracy
    """
    model_modules = [
        "models.xgboost_model", "models.logistic_model", "models.rf_model",
        "models.nb_model", "models.svm_model", "models.gbm_model", "models.linear_model",
        "models.deep_learning_model", "models.pattern_recognition_model"
    ]
    
    results = []
    for module_name in model_modules:
        try:
            print(f"Running 5-Fold CV: {module_name}...")
            module = importlib.import_module(module_name)
            model = module.get_model()
            
            cv_results = run_5_fold_cv(model, X, y)
            
            fold_metrics = []
            for y_val, y_prob in cv_results:
                y_pred = (y_prob >= 0.5).astype(int)
                fold_metrics.append(get_classification_metrics(y_val, y_pred, y_prob))
            
            mean_metrics = pd.DataFrame(fold_metrics).mean().to_dict()
            mean_metrics["model"] = module_name.split('.')[-1]
            results.append(mean_metrics)
        except Exception as e:
            print(f"Failed to run {module_name}: {e}")
            
    return pd.DataFrame(results).sort_values(by="auc", ascending=False)
