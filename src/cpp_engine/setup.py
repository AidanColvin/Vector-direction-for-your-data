from setuptools import setup, Extension
import pybind11

ext_modules = [
    Extension(
        "biobeat_cleaning",
        ["cleaning/remove_invalids.cpp", "cleaning/calculate_median.cpp", "cleaning/bindings.cpp"],
        include_dirs=[pybind11.get_include()],
        language="c++",
        extra_compile_args=["-std=c++11", "-O3"]
    ),
    Extension(
        "biobeat_scaling",
        ["scaling/calculate_mean.cpp", "scaling/calculate_std.cpp", "scaling/apply_standardization.cpp", "scaling/bindings.cpp"],
        include_dirs=[pybind11.get_include()],
        language="c++",
        extra_compile_args=["-std=c++11", "-O3"]
    ),
]

setup(
    name="biobeat_cpp_engine",
    version="1.0",
    ext_modules=ext_modules,
)
