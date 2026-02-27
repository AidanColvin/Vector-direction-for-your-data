#include <vector>
#include <numeric>
#include "scaling.h"

/*
given a vector of doubles
return a double representing the mathematical mean
returns 0.0 if vector is empty
*/
double calculate_mean(const std::vector<double>& column) {
    if (column.empty()) return 0.0;
    
    double sum = std::accumulate(column.begin(), column.end(), 0.0);
    return sum / column.size();
}
