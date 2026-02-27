import os
import sys
from pathlib import Path

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from io.header_parser import get_column_mapping
from io.column_combiner import combine_columns_to_csv
from process_dataset import process_single_feature

def run_full_pipeline(raw_csv_path: str, output_dir: str, final_csv_name: str) -> None:
    """
    given a raw csv path, a temporary output directory, and a final file name
    read headers
    process each numeric column individually via c++ engine
    combine all processed columns into one final dataset
    """
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    col_mapping = get_column_mapping(raw_csv_path)
    
    processed_files = []
    
    for col_index, header in col_mapping.items():
        # Skip ID and categorical targets for standard scaling
        if header.lower() in ["id", "smoking", "diagnosed_diabetes"]:
            continue
            
        temp_out = os.path.join(output_dir, f"temp_{header}.csv")
        
        try:
            process_single_feature(raw_csv_path, temp_out, col_index, header)
            processed_files.append(temp_out)
        except Exception as e:
            print(f"Skipping {header} due to error: {e}")
            
    final_out_path = os.path.join(output_dir, final_csv_name)
    print(f"Combining {len(processed_files)} columns into {final_out_path}...")
    combine_columns_to_csv(processed_files, final_out_path)
    
    # Cleanup temporary 1D column files
    for f in processed_files:
        os.remove(f)
        
    print("Pipeline execution complete. Your dataset is now preprocessed and memory-safe.")

if __name__ == "__main__":
    # Target Kaggle paths from your architecture
    RAW_TRAIN = "data/raw/train.csv"
    PROCESSED_DIR = "data/processed"
    FINAL_NAME = "train_standardized_cpp.csv"
    
    # Ensure raw directory exists before trying to read
    if os.path.exists(RAW_TRAIN):
        run_full_pipeline(RAW_TRAIN, PROCESSED_DIR, FINAL_NAME)
    else:
        print(f"Error: {RAW_TRAIN} not found. Please ensure your Kaggle dataset is unzipped here.")
