#include <vector>
#include <cmath>
#include "cleaning.h"

/*
given a vector of doubles
return a new vector of doubles
infinite values removed
nan values removed
*/
std::vector<double> remove_invalids(const std::vector<double>& column) {
    std::vector<double> clean_column;
    // Pre-allocate memory to prevent expensive resizing during the loop
    clean_column.reserve(column.size());
    
    for (double val : column) {
        if (!std::isinf(val) && !std::isnan(val)) {
            clean_column.push_back(val);
        }
    }
    
    return clean_column;
}
