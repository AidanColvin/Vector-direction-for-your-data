#include <vector>
#include <cmath>
#include "scaling.h"

/*
given a vector of doubles and its mean
return a double representing the sample standard deviation
returns 1.0 for zero variance or empty vectors to prevent division by zero
*/
double calculate_std(const std::vector<double>& column, double mean) {
    if (column.size() <= 1) return 1.0;
    
    double variance_sum = 0.0;
    for (double val : column) {
        variance_sum += (val - mean) * (val - mean);
    }
    
    double std_dev = std::sqrt(variance_sum / (column.size() - 1));
    
    // safe fallback for zero variance
    if (std_dev == 0.0) return 1.0;
    return std_dev;
}
