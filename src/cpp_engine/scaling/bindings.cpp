#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include "scaling.h"

namespace py = pybind11;

/*
creates python bindings for the c++ scaling engine
exposes mean, std, and standardization functions
*/
PYBIND11_MODULE(biobeat_scaling, m) {
    m.doc() = "c++ scaling engine for biobeat pipeline";
    m.def("calculate_mean", &calculate_mean, "calculates mean of a list");
    m.def("calculate_std", &calculate_std, "calculates standard deviation of a list");
    m.def("apply_standardization", &apply_standardization, "applies standard scaling to a list");
}
