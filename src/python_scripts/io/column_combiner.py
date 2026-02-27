import csv
from typing import List

def combine_columns_to_csv(input_files: List[str], output_file: str) -> None:
    """
    given a list of single-column csv file paths and an output path
    write a combined csv file side-by-side
    processes row by row to maintain memory safety
    """
    file_handles = [open(f, 'r', encoding='utf-8') for f in input_files]
    readers = [csv.reader(fh) for fh in file_handles]
    
    with open(output_file, 'w', encoding='utf-8', newline='') as out_f:
        writer = csv.writer(out_f)
        
        for rows in zip(*readers):
            # Flatten the list of single-element lists
            combined_row = [row[0] if row else "" for row in rows]
            writer.writerow(combined_row)
            
    for fh in file_handles:
        fh.close()
