from sklearn.metrics import accuracy_score, roc_auc_score, f1_score, precision_score, recall_score
from typing import Dict
import numpy as np

def get_classification_metrics(y_true: np.ndarray, y_pred: np.ndarray, y_prob: np.ndarray) -> Dict[str, float]:
    """
    given true labels, binary predictions, and probabilities
    return a dictionary of performance metrics
    handles binary classification
    """
    return {
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "auc": float(roc_auc_score(y_true, y_prob)),
        "f1": float(f1_score(y_true, y_pred)),
        "precision": float(precision_score(y_true, y_pred, zero_division=0)),
        "recall": float(recall_score(y_true, y_pred, zero_division=0))
    }
