#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include "cleaning.h"

namespace py = pybind11;

/*
creates python bindings for the c++ engine
exposes cleaning module functions
handles type conversion between std::vector and python list
*/
PYBIND11_MODULE(biobeat_cleaning, m) {
    m.doc() = "c++ cleaning engine for biobeat pipeline";
    m.def("remove_invalids", &remove_invalids, "removes infinite and nan values from a list");
    m.def("calculate_median", &calculate_median, "calculates the median of a list");
}
