import numpy as np
import importlib
import pytest

@pytest.mark.parametrize("model_name", [
    "xgboost_model", "logistic_model", "rf_model", "nb_model",
    "svm_model", "gbm_model", "linear_model", "deep_learning_model",
    "pattern_recognition_model", "tabnet_model", "transformer_model"
])
def test_model_flow(model_name):
    """
    verifies each of the 11 models can fit and predict
    uses a small synthetic dataset
    """
    module = importlib.import_module(f"models.{model_name}")
    model = module.get_model() if hasattr(module, 'get_model') else module.get_xgboost_classifier()
    
    X = np.random.rand(100, 5)
    y = np.random.randint(0, 2, 100)
    
    model.fit(X, y)
    probs = model.predict_proba(X)
    
    assert probs.shape == (100, 2)
    assert np.all(probs >= 0) and np.all(probs <= 1)
