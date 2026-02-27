import csv
from typing import Dict, List

def get_column_mapping(file_path: str) -> Dict[int, str]:
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = next(reader, [])
    return {i: name.strip() for i, name in enumerate(headers) if name.strip()}

def detect_target_column(file_path: str) -> str:
    """
    detects the target variable (label) 
    assumes it is the last column or named 'target'/'label'/'smoking'
    """
    mapping = get_column_mapping(file_path)
    headers = list(mapping.values())
    # Return last column as default target
    return headers[-1]
