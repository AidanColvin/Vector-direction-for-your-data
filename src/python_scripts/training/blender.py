import pandas as pd
import os
from typing import List

def blend_submissions(submission_dir: str, output_path: str):
    """
    given a directory of submission csv files
    average the 'smoking' probability across all files
    write the final blended submission to disk
    """
    sub_files = [f for f in os.listdir(submission_dir) if f.endswith('.csv') and 'blended' not in f]
    
    if not sub_files:
        print("No submission files found to blend.")
        return

    print(f"Blending {len(sub_files)} models...")
    
    blended_df = None
    
    for i, file in enumerate(sub_files):
        path = os.path.join(submission_dir, file)
        df = pd.read_csv(path)
        
        if i == 0:
            blended_df = df.copy()
        else:
            blended_df['smoking'] += df['smoking']
            
    # Calculate the average probability
    blended_df['smoking'] /= len(sub_files)
    
    blended_df.to_csv(output_path, index=False)
    print(f"✅ Blended submission saved to: {output_path}")

if __name__ == "__main__":
    blend_submissions("data/processed/submissions", "data/processed/submissions/blended_final.csv")
