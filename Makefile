# BioBeat Pipeline Master Controller

.PHONY: build clean run

build:
	cd src/cpp_engine && python3 setup.py build_ext --inplace

clean:
	rm -rf data/processed/visualizations/*
	rm -rf data/processed/submissions/*
	rm -rf src/cpp_engine/build

run:
	python3 src/python_scripts/run_preprocessing.py
	python3 src/python_scripts/main_full_run.py

test:
	pytest tests/python_tests/
