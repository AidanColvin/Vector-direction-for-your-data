import biobeat_scaling
from typing import List, Tuple

def get_scaling_parameters(column_data: List[float]) -> Tuple[float, float]:
    """
    given a list of numeric floats representing training data
    return a tuple of (mean, standard_deviation)
    calculated via c++ engine
    """
    if not column_data:
        return (0.0, 1.0)
        
    mean = biobeat_scaling.calculate_mean(column_data)
    std = biobeat_scaling.calculate_std(column_data, mean)
    return (mean, std)

def scale_column(column_data: List[float], mean: float, std: float) -> List[float]:
    """
    given a list of numeric floats, mean, and std
    return a new list of scaled values
    applied via c++ engine
    """
    if not column_data:
        return []
        
    return biobeat_scaling.apply_standardization(column_data, mean, std)
