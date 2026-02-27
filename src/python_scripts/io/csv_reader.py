import csv
from typing import List

def get_numeric_column(file_path: str, column_index: int, has_header: bool = True) -> List[float]:
    """
    given a path to a csv file and a column index
    return a list of floats for that specific column
    skips header if specified
    ignores empty strings and invalid text
    """
    column_data = []
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        if has_header:
            next(reader, None)
            
        for row in reader:
            if len(row) > column_index:
                val = row[column_index].strip()
                if val:
                    try:
                        column_data.append(float(val))
                    except ValueError:
                        pass
                        
    return column_data
