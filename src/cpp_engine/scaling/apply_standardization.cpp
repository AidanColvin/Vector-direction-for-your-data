#include <vector>
#include "scaling.h"

/*
given a vector of doubles, the mean, and the standard deviation
return a new vector of standardized doubles
applies z-score formula to each element
*/
std::vector<double> apply_standardization(const std::vector<double>& column, double mean, double std_dev) {
    std::vector<double> scaled_column;
    scaled_column.reserve(column.size());
    
    for (double val : column) {
        scaled_column.push_back((val - mean) / std_dev);
    }
    
    return scaled_column;
}
