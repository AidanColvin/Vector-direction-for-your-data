import pandas as pd
from typing import List

def write_kaggle_submission(test_ids: List[int], predictions: List[float], output_path: str) -> None:
    """
    given a list of test ids and probability predictions
    write a formatted csv for kaggle submission
    matches sample_submission.csv format
    """
    df = pd.DataFrame({
        "id": test_ids,
        "smoking": predictions
    })
    df.to_csv(output_path, index=False)
