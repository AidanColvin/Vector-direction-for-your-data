import pandas as pd

def apply_feature_engineering(df: pd.DataFrame) -> pd.DataFrame:
    """
    given a dataframe of bio-signals
    return a dataframe with new interaction features
    based on standard medical indicators (e.g., height/weight ratio)
    """
    # 1. Body Mass Index (BMI) proxy
    if 'height(cm)' in df.columns and 'weight(kg)' in df.columns:
        df['bmi_proxy'] = df['weight(kg)'] / ((df['height(cm)'] / 100) ** 2)

    # 2. Cardiovascular Risk Interaction
    if 'systolic' in df.columns and 'relaxation' in df.columns:
        df['pulse_pressure'] = df['systolic'] - df['relaxation']
        
    # 3. Liver/Metabolism Ratio
    if 'GTP' in df.columns and 'ALT' in df.columns:
        df['gtp_alt_ratio'] = df['GTP'] / (df['ALT'] + 1) # avoid div by zero
        
    return df
