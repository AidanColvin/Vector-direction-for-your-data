import pandas as pd
from typing import Tuple, List

def validate_schemas(train_path: str, test_path: str, target_col: str) -> Tuple[bool, str]:
    """
    given paths to train and test files
    verify that test has all features present in train (minus target)
    returns (is_valid, error_message)
    """
    try:
        train_cols = pd.read_csv(train_path, nrows=0).columns.tolist()
        test_cols = pd.read_csv(test_path, nrows=0).columns.tolist()
        
        # Features are everything except the target
        train_features = [c for c in train_cols if c != target_col]
        
        missing_in_test = [c for c in train_features if c not in test_cols]
        
        if missing_in_test:
            return False, f"Missing columns in Test file: {', '.join(missing_in_test)}"
            
        if len(train_features) == 0:
            return False, "Training file has no feature columns."
            
        return True, "Schema Validated: Train and Test features match."
    except Exception as e:
        return False, f"Schema Check Failed: {str(e)}"
