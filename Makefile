# BioBeat Pipeline Master Controller
PYTHON = ./.venv/bin/python3
PIP = ./.venv/bin/pip3

.PHONY: build clean run test install

install:
	$(PIP) install -r requirements.txt

build:
	cd src/cpp_engine && $(PYTHON) setup.py build_ext --inplace

clean:
	rm -rf data/processed/visualizations/*
	rm -rf data/processed/submissions/*
	rm -rf src/cpp_engine/build
	find . -name "*.so" -delete

run:
	$(PYTHON) src/python_scripts/run_preprocessing.py
	$(PYTHON) src/python_scripts/main_full_run.py

test:
	$(PYTHON) -m pytest tests/python_tests/
