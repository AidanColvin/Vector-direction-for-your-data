#include <vector>
#include <algorithm>
#include "cleaning.h"

/*
given a vector of doubles
return a double representing the median
sorts vector to find middle value
returns 0.0 if empty
*/
double calculate_median(std::vector<double> column) {
    if (column.empty()) {
        return 0.0;
    }
    
    size_t n = column.size() / 2;
    // nth_element is highly optimized and memory efficient
    std::nth_element(column.begin(), column.begin() + n, column.end());
    
    if (column.size() % 2 == 0) {
        auto max_it = std::max_element(column.begin(), column.begin() + n);
        return (*max_it + column[n]) / 2.0;
    }
    
    return column[n];
}
