#ifndef SCALING_H
#define SCALING_H

#include <vector>

double calculate_mean(const std::vector<double>& column);
double calculate_std(const std::vector<double>& column, double mean);
std::vector<double> apply_standardization(const std::vector<double>& column, double mean, double std_dev);

#endif
