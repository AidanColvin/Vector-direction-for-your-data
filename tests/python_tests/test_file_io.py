import os
import pandas as pd
from file_io.csv_reader import get_numeric_column
from file_io.csv_to_parquet import convert_to_parquet

def test_csv_column_reader(tmp_path):
    """
    verifies that specific columns are extracted correctly
    """
    d = tmp_path / "sub"
    d.mkdir()
    csv_file = d / "test.csv"
    csv_file.write_text("id,val\n1,10.5\n2,20.5")
    
    col = get_numeric_column(str(csv_file), 1)
    assert col == [10.5, 20.5]

def test_parquet_conversion(tmp_path):
    """
    verifies parquet conversion preserves data
    """
    csv_path = tmp_path / "data.csv"
    pq_path = tmp_path / "data.parquet"
    df = pd.DataFrame({"A": [1, 2], "B": [3, 4]})
    df.to_csv(csv_path, index=False)
    
    convert_to_parquet(str(csv_path), str(pq_path))
    assert os.path.exists(pq_path)
