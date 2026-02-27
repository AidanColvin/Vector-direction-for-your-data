import os
import sys
from pathlib import Path

# Add script directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from file_io.header_parser import get_column_mapping
from file_io.column_combiner import combine_columns_to_csv
from process_dataset import process_single_feature

def run_full_pipeline(raw_csv_path: str, output_dir: str, final_csv_name: str) -> None:
    """
    given a raw csv path, a temporary output directory, and a final file name
    executes c++ cleaning and scaling per column
    """
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    col_mapping = get_column_mapping(raw_csv_path)
    
    processed_files = []
    for col_index, header in col_mapping.items():
        if header.lower() in ["id", "smoking", "diagnosed_diabetes"]:
            continue
            
        temp_out = os.path.join(output_dir, f"temp_{header}.csv")
        try:
            process_single_feature(raw_csv_path, temp_out, col_index, header)
            processed_files.append(temp_out)
        except Exception as e:
            print(f"Skipping {header}: {e}")
            
    final_out_path = os.path.join(output_dir, final_csv_name)
    combine_columns_to_csv(processed_files, final_out_path)
    
    for f in processed_files:
        os.remove(f)
    print("Preprocessing complete.")

if __name__ == "__main__":
    RAW_TRAIN = "data/raw/train.csv"
    PROCESSED_DIR = "data/processed"
    FINAL_NAME = "train_standardized_cpp.csv"
    
    if os.path.exists(RAW_TRAIN):
        run_full_pipeline(RAW_TRAIN, PROCESSED_DIR, FINAL_NAME)
    else:
        print(f"Error: {RAW_TRAIN} not found.")
