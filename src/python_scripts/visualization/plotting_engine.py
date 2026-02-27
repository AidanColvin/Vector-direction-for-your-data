import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import roc_curve, confusion_matrix
import pandas as pd
import numpy as np

def save_model_visuals(y_true: np.ndarray, y_prob: np.ndarray, model_name: str, output_dir: str):
    """
    given true labels, probabilities, and model name
    generates and saves ROC curve and Confusion Matrix
    """
    plt.style.use('ggplot')
    
    # 1. ROC Curve
    fpr, tpr, _ = roc_curve(y_true, y_prob)
    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, label=f'ROC (Area = {np.trapz(tpr, fpr):.2f})')
    plt.plot([0, 1], [0, 1], 'k--')
    plt.title(f'ROC Curve: {model_name}')
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.legend(loc='lower right')
    plt.savefig(f"{output_dir}/{model_name}_roc.png")
    plt.close()

    # 2. Confusion Matrix
    y_pred = (y_prob >= 0.5).astype(int)
    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(6, 5))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
    plt.title(f'Confusion Matrix: {model_name}')
    plt.ylabel('Actual')
    plt.xlabel('Predicted')
    plt.savefig(f"{output_dir}/{model_name}_cm.png")
    plt.close()
