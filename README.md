# BioBeat: Smoker Status Prediction — Hybrid Pipeline

A high-performance machine learning pipeline utilizing a **C++ Engine** for numerical scaling, **Python** for 11-model supervised training, and **R** for publication-ready visual comparisons.

### System Architecture
1. **Engine:** C++11 (Standardization and Cleaning)
2. **Data Format:** Apache Parquet (Memory-Safe)
3. **Models:** 11 Supervised & Deep Learning Architectures
4. **Validation:** Stratified 5-Fold Cross-Validation

### Quickstart
- Run `make build` to compile C++ bindings.
- Run `make run` to execute the full pipeline.
- Access the Web UI via the GitHub Pages URL.

### Verified Sources
Mathematical foundations for scaling and metrics follow standard implementations found in JAMA-referenced medical data processing and .gov/edu statistical guidelines.
