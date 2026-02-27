#ifndef CLEANING_H
#define CLEANING_H

#include <vector>

std::vector<double> remove_invalids(const std::vector<double>& column);
double calculate_median(std::vector<double> column);

#endif
