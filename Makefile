# BioBeat Universal Makefile
ROOT_DIR := $(shell pwd)
PYTHON = $(ROOT_DIR)/.venv/bin/python3

.PHONY: build run_sandbox

build:
	cd src/cpp_engine && $(PYTHON) setup.py build_ext --inplace

# Run the pipeline against a specific sandbox directory
run_sandbox:
	$(PYTHON) src/python_scripts/run_preprocessing.py --data_dir $(DATA)
	$(PYTHON) src/python_scripts/main_full_run.py --data_dir $(DATA) --target $(TARGET)
