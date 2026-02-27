import sys
import os
from pathlib import Path

# Add the script's parent directory to path to allow absolute-style imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from file_io.csv_reader import get_numeric_column
from file_io.csv_writer import write_single_column
from cleaning.impute_strategy import get_clean_median
from scaling.standardize import get_scaling_parameters, scale_column

def process_single_feature(input_csv: str, output_csv: str, col_index: int, header: str) -> None:
    """
    given input, output, index, and header
    process column via C++ scaling engine
    """
    raw_data = get_numeric_column(input_csv, col_index)
    mean, std = get_scaling_parameters(raw_data)
    scaled_data = scale_column(raw_data, mean, std)
    write_single_column(output_csv, scaled_data, header)
