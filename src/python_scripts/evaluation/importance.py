import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def get_feature_importance(model: Any, feature_names: list, model_name: str, output_dir: str):
    """
    given a trained model and feature names
    extract importance or coefficients
    save a bar chart of the top 10 features
    """
    if hasattr(model, 'feature_importances_'):
        importance = model.feature_importances_
    elif hasattr(model, 'coef_'):
        importance = np.abs(model.coef_[0])
    else:
        return # Skip models without direct importance attributes

    df = pd.DataFrame({'feature': feature_names, 'importance': importance})
    df = df.sort_values(by='importance', ascending=False).head(10)

    plt.figure(figsize=(10, 6))
    plt.barh(df['feature'], df['importance'], color='skyblue')
    plt.gca().invert_yaxis()
    plt.title(f'Top 10 Features: {model_name}')
    plt.savefig(f"{output_dir}/{model_name}_importance.png")
    plt.close()
