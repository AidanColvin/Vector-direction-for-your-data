import csv
from typing import Dict

def get_column_mapping(file_path: str) -> Dict[int, str]:
    """
    given a path to a csv file
    return a dictionary mapping column index to header name
    reads only the first row
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = next(reader, [])
        
    return {i: name.strip() for i, name in enumerate(headers) if name.strip()}
