# Vector Master Pipeline Controller
ROOT_DIR := $(shell pwd)
PYTHON = $(ROOT_DIR)/.venv/bin/python3
PIP = $(ROOT_DIR)/.venv/bin/pip3

.PHONY: build clean run test install install-core

install:
	$(PIP) install -r requirements.txt

install-core:
	$(PIP) uninstall -y numpy pandas scikit-learn
	$(PIP) install --no-cache-dir numpy pandas scikit-learn

build:
	cd src/cpp_engine && $(PYTHON) setup.py build_ext --inplace

clean:
	rm -rf data/processed/visualizations/*
	rm -rf data/processed/submissions/*
	rm -rf src/cpp_engine/build
	find . -name "*.so" -delete

run:
	@echo "🚀 Starting Vector Directional Analysis..."
	$(PYTHON) src/python_scripts/run_preprocessing.py
	$(PYTHON) src/python_scripts/main_full_run.py

test:
	$(PYTHON) -m pytest tests/python_tests/
