import biobeat_cleaning
from typing import List

def get_clean_median(column_data: List[float]) -> float:
    """
    given a list of numeric floats representing a column
    return the median value
    uses c++ engine to strip invalids first
    uses c++ engine to calculate median
    """
    if not column_data:
        return 0.0

    clean_data = biobeat_cleaning.remove_invalids(column_data)
    return biobeat_cleaning.calculate_median(clean_data)
