from sklearn.model_selection import StratifiedKFold
from typing import Any, Tuple, List
import numpy as np

def run_5_fold_cv(model: Any, X: np.ndarray, y: np.ndarray) -> List[Tuple[np.ndarray, np.ndarray]]:
    """
    given a model, feature matrix, and target array
    return a list of out-of-fold predictions and true labels
    executes 5-fold stratified cross-validation
    """
    skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    oof_results = []
    
    for train_index, val_index in skf.split(X, y):
        X_train, X_val = X[train_index], X[val_index]
        y_train, y_val = y[train_index], y[val_index]
        
        model.fit(X_train, y_train)
        y_prob = model.predict_proba(X_val)[:, 1]
        
        oof_results.append((y_val, y_prob))
        
    return oof_results
