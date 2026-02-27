# Vector Universal Makefile
PYTHON = python3
PIP = pip3

.PHONY: build clean run

build:
	cd src/cpp_engine && $(PYTHON) setup.py build_ext --inplace

clean:
	rm -rf data/processed/*
	find . -name "*.so" -delete

run:
	$(PYTHON) src/python_scripts/run_preprocessing.py
	$(PYTHON) src/python_scripts/main_full_run.py
