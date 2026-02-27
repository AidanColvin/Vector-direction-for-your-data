import pandas as pd
import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from io.submission_writer import write_kaggle_submission

def create_submission(model, test_csv_path: str, output_path: str):
    """
    given a trained model and test csv
    predict probabilities for 'smoking'
    save as kaggle-ready csv
    """
    test_df = pd.read_csv(test_csv_path)
    test_ids = test_df['id'].tolist()
    
    # Ensure features match what the model saw
    X_test = test_df.drop(columns=['id']).values
    
    probs = model.predict_proba(X_test)[:, 1]
    
    write_kaggle_submission(test_ids, probs, output_path)
    print(f"Submission saved to {output_path}")
