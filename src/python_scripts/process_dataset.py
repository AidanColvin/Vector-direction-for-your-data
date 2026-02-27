import sys
import os
from pathlib import Path

# Add local modules to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from io.csv_reader import get_numeric_column
from io.csv_writer import write_single_column
from cleaning.impute_strategy import get_clean_median
from scaling.standardize import get_scaling_parameters, scale_column

def process_single_feature(input_csv: str, output_csv: str, col_index: int, header: str) -> None:
    """
    given input file, output file, column index, and header name
    read column from raw data
    calculate scaling parameters via c++ engine
    scale data via c++ engine
    write scaled data to new csv
    """
    print(f"Processing column: {header}...")
    
    # 1. Read one column into memory
    raw_data = get_numeric_column(input_csv, col_index)
    
    # 2. Calculate scaling parameters using C++
    mean, std = get_scaling_parameters(raw_data)
    
    # 3. Apply standard scaling using C++
    scaled_data = scale_column(raw_data, mean, std)
    
    # 4. Write processed column to disk
    write_single_column(output_csv, scaled_data, header)
    print(f"Finished {header}. Mean: {mean:.4f}, Std: {std:.4f}")

if __name__ == "__main__":
    # Example usage
    print("Pipeline ready to process columns.")
