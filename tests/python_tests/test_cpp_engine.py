import biobeat_cleaning
import biobeat_scaling
import numpy as np
import pytest

def test_remove_invalids():
    """
    verifies c++ engine removes nan and inf
    """
    data = [1.0, float('nan'), 2.0, float('inf'), 3.0]
    result = biobeat_cleaning.remove_invalids(data)
    assert result == [1.0, 2.0, 3.0]

def test_calculate_median():
    """
    verifies c++ median calculation
    """
    data = [3.0, 1.0, 2.0]
    result = biobeat_cleaning.calculate_median(data)
    assert result == 2.0

def test_scaling_math():
    """
    verifies c++ mean and std calculation
    """
    data = [10.0, 20.0, 30.0]
    mean = biobeat_scaling.calculate_mean(data)
    std = biobeat_scaling.calculate_std(data, mean)
    assert mean == 20.0
    assert pytest.approx(std, 0.01) == 10.0
