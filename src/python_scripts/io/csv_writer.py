import csv
from typing import List

def write_single_column(file_path: str, column_data: List[float], header_name: str) -> None:
    """
    given a path, data list, and header string
    write a single column csv file
    creates new file or overwrites existing
    """
    with open(file_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([header_name])
        
        for val in column_data:
            writer.writerow([val])
