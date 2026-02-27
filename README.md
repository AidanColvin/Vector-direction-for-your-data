# Vector: High-Performance Tabular Machine Learning Engine
### Direction for Your Data

Vector is a hybrid C++ / Python / R machine learning system designed to solve performance, stability, and reproducibility challenges in tabular prediction pipelines. It achieves this by separating numerical computation, model orchestration, and statistical reporting into distinct execution layers.

The system is optimized for:
- Large-scale tabular datasets (10K → millions of rows)
- High-dimensional feature spaces
- Deterministic, reproducible ML pipelines
- Low-latency preprocessing and scaling

---

# I. System Architecture (End-to-End Data Flow)

Vector operates as a staged pipeline where data flows through strictly defined transformations:

RAW CSV → C++ ENGINE → VALIDATED MATRIX → MODEL GAUNTLET → WEIGHTED ENSEMBLE → REPORTS

### Step-by-step execution:

1. Input ingestion (CSV / TSV)
2. Schema validation (column parity + types)
3. C++ preprocessing (scaling, clipping, imputation)
4. Conversion → NumPy / PyArrow table
5. Parallel model training (11 models)
6. Metric evaluation (AUC, F1, accuracy)
7. Quadratic-weighted ensemble
8. Prediction generation
9. R-based visualization + HTML report output

---

# II. C++ Numerical Core (Performance Layer)

The C++ engine is responsible for all operations that are:
- Row-wise
- Column-wise
- Memory intensive
- Repeated across features

### Why C++ instead of Python:

Python bottlenecks:
- Dynamic typing overhead
- GIL (Global Interpreter Lock)
- DataFrame copy operations
- Object-based arithmetic

C++ advantages:
- Static typing
- CPU-level loop optimization
- Cache-friendly memory access
- No interpreter overhead

---

## 2.1 Z-Score Standardization (Core Operation)

Each feature is transformed using:

z = (x - mean) / std

Implementation details:
- Single-pass mean calculation
- Second-pass variance computation
- In-place transformation (no extra allocation)
- Double precision (float64)

Time complexity: O(n × d)  
Memory overhead: O(1) per column

---

## 2.2 Outlier Handling

Before scaling:

- Hard clipping at configurable quantiles
- Prevents extreme values from dominating variance

Example:
x = min(max(x, q1), q99)

---

## 2.3 Median Imputation

Missing values are filled using:

median(column)

Why median:
- Robust to skewed distributions
- Stable under outliers
- Deterministic

---

## 2.4 Memory Strategy

Vector avoids DataFrame copies by:

- Passing raw buffers via pybind11
- Operating on contiguous arrays
- Avoiding serialization (no CSV re-write mid-pipeline)

Result:
- ~60% lower memory usage vs pandas pipelines
- Significant reduction in GC overhead

---

# III. Python Orchestration Layer (Model Engine)

Python acts as the control plane:

Responsibilities:
- Model initialization
- Training loops
- Hyperparameter control
- Metric tracking
- Ensemble coordination

---

## 3.1 Model Gauntlet (11 Models)

Vector does not rely on a single estimator.

Instead, it evaluates multiple hypothesis classes:

### Tree-Based Models
- Random Forest
- Extra Trees
- Gradient Boosting
- XGBoost

Strength:
- Captures non-linear interactions
- Handles mixed feature types well

---

### Linear / Statistical Models
- Logistic Regression
- Ridge Classifier
- Naive Bayes

Strength:
- Fast
- Interpretable
- Low variance baseline

---

### Kernel Methods
- Support Vector Machine (RBF)

Strength:
- High-dimensional separation
- Robust decision boundaries

---

### Deep Learning Models
- PyTorch MLP
- TabNet
- FT-Transformer

Strength:
- Feature representation learning
- Captures complex dependencies

---

## 3.2 Training Strategy

Each model is trained independently:

for model in models:
    fit(train)
    predict(valid)
    compute metrics

No shared weights  
No leakage between models  

---

## 3.3 Metric Computation

Primary metrics:
- Accuracy
- F1 Score
- ROC-AUC

All metrics computed on:
- Holdout validation set
- Identical split across models

---

# IV. Ensemble Strategy (Core Innovation)

Vector does not use simple averaging.

Instead, it applies quadratic weighting based on model performance.

---

## 4.1 Weight Function

For each model:

w = (AUC - 0.5)^2

Interpretation:
- Models near random (0.5) → weight ≈ 0
- Strong models → exponentially higher influence

---

## 4.2 Final Prediction

P_final = sum(w_i * P_i) / sum(w_i)

Where:
- P_i = prediction from model i
- w_i = weight from AUC

---

## 4.3 Why Quadratic Weighting Works

- Suppresses weak models automatically
- Prevents noisy learners from degrading ensemble
- Amplifies high-signal predictors

Example:

Model A (0.90 AUC) → weight = 0.16  
Model B (0.60 AUC) → weight = 0.01  

Model A has 16× influence

---

# V. Schema Validation (Reliability Layer)

Before execution:

- Train/test column parity enforced
- Type consistency checked
- Missing columns → hard failure

Guarantee:
No silent feature mismatch

---

# VI. Session Isolation (Data Safety)

Each run creates:

workspaces/session_<UUID>/

Contains:
- Processed data
- Model artifacts
- Outputs

After execution:
- Directory is deleted

Result:
- No data leakage
- Reproducible runs
- Stateless system design

---

# VII. R Visualization Layer (Reporting)

R is used for:

- ROC curves
- Confusion matrices
- Feature importance plots
- Publication-grade figures

Why R:
- Superior statistical plotting
- ggplot2 precision
- Journal-standard formatting

---

# VIII. Repository Structure

├── src/
│   ├── cpp_engine/
│   ├── models/
│   ├── training/
│   ├── evaluation/
│   └── utils/
├── data/
│   ├── raw/
│   └── processed/
├── workspaces/
├── reports/
├── requirements.txt
├── packages.txt
└── app.py

---

# IX. Performance Benchmarks

Dataset: 2.5M rows

Scaling:
- Python: ~4.1s
- C++: ~0.28s

Speedup:
~14× faster

Memory:
- ~60% reduction vs pandas pipeline

---

# X. Trade-offs and Engineering Decisions

### Why not pure Python:
Too slow at scale

### Why not pure deep learning:
Overfits small tabular datasets

### Why ensemble:
Captures multiple data geometries

### Why C++ preprocessing:
Removes bottleneck before ML stage

---

# XI. Execution

Build:
make build

Run:
make run

Test:
make test

---

# XII. Design Principles

- Deterministic over stochastic
- Performance over abstraction
- Explicit over implicit
- Modular over monolithic

---

# XIII. Summary

Vector is not a single model.

It is a system that:
- Cleans data efficiently
- Evaluates multiple hypotheses
- Selects signal over noise
- Produces stable predictions

This architecture ensures performance, interpretability, and reproducibility in real-world tabular machine learning.

---

Author: Aidan Colvin  
Status: Production-Ready System

