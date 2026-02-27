import optuna
import numpy as np
from sklearn.model_selection import cross_val_score
from typing import Any, Dict

def tune_hyperparameters(model_class: Any, X: np.ndarray, y: np.ndarray, n_trials: int = 20) -> Dict[str, Any]:
    """
    given a model class and data
    run bayesian optimization via optuna
    return the best parameter dictionary found
    """
    def objective(trial):
        # Example for tree-based models; can be expanded per model type
        params = {
            'n_estimators': trial.suggest_int('n_estimators', 50, 300),
            'max_depth': trial.suggest_int('max_depth', 3, 10),
            'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.3, log=True)
        }
        
        model = model_class(**params)
        # Using a simple 3-fold CV inside the tuner for speed
        score = cross_val_score(model, X, y, cv=3, scoring='roc_auc').mean()
        return score

    study = optuna.create_study(direction='maximize')
    study.optimize(objective, n_trials=n_trials)
    
    print(f"Optimization finished. Best AUC: {study.best_value:.4f}")
    return study.best_params
