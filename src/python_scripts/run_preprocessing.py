import sys, os; sys.path.append(os.path.join(os.getcwd(), 'src/cpp_engine'))
import os
import sys
import pandas as pd
from pathlib import Path

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from file_io.header_parser import get_column_mapping
from file_io.column_combiner import combine_columns_to_csv
from process_dataset import process_single_feature
from engineering.interactions import apply_feature_engineering

def run_full_pipeline(raw_csv_path: str, output_dir: str, final_csv_name: str) -> None:
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    col_mapping = get_column_mapping(raw_csv_path)
    
    processed_files = []
    for col_index, header in col_mapping.items():
        if header.lower() in ["id", "smoking", "diagnosed_diabetes"]:
            continue
        temp_out = os.path.join(output_dir, f"temp_{header}.csv")
        process_single_feature(raw_csv_path, temp_out, col_index, header)
        processed_files.append(temp_out)
            
    final_out_path = os.path.join(output_dir, final_csv_name)
    combine_columns_to_csv(processed_files, final_out_path)
    
    # Load combined data and apply feature engineering
    df = pd.read_csv(final_out_path)
    df = apply_feature_engineering(df)
    
    # Add back the labels/IDs (Assuming they are needed for training)
    # This is a critical step for your specific Kaggle dataset
    raw_df = pd.read_csv(raw_csv_path)
    if 'smoking' in raw_df.columns:
        df['smoking'] = raw_df['smoking']
    
    df.to_parquet(final_out_path.replace('.csv', '.parquet'), index=False)
    print("✅ Preprocessing & Engineering Complete.")

if __name__ == "__main__":
    run_full_pipeline("data/raw/train.csv", "data/processed", "train_standardized_cpp.csv")
