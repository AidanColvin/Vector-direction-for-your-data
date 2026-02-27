import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import os

def convert_to_parquet(csv_path: str, parquet_path: str) -> None:
    """
    given a path to a csv file
    convert and save as a parquet file
    uses pyarrow engine for memory efficiency
    """
    if not os.path.exists(csv_path):
        print(f"Error: {csv_path} not found.")
        return

    # Reading in chunks if file is massive, but for Kaggle playground, 
    # a standard read with pyarrow engine is typically safe.
    df = pd.read_csv(csv_path, engine='pyarrow')
    df.to_parquet(parquet_path, engine='pyarrow', index=False)
    print(f"Converted {csv_path} to {parquet_path}")
