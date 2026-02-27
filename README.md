# 🧬 BioBeat-Smoker-Status-Prediction
### Hybrid C++ / Python / R Machine Learning Engine

A universally adaptable, high-performance pipeline for tabular data prediction. Originally designed for the Kaggle Smoker Status competition, this engine utilizes a C++ core for numerical efficiency and an ensemble of 11 models for predictive power.

---

## 🚀 Key Features
- **Hybrid Performance:** C++11 Engine for memory-safe cleaning and scaling (O3 optimization).
- **Ensemble Gauntlet:** Automatically trains and compares 11 architectures:
  - *Tree-based:* XGBoost, Random Forest, GBM, ExtraTrees.
  - *Deep Learning:* PyTorch MLP, TabNet (Google), FT-Transformer (BERT-style).
  - *Statistical:* Logistic Regression, Naive Bayes, SVM, Ridge.
- **Auto-Schema Validation:** Ensures `train` and `test` compatibility before execution.
- **Session Isolation:** Dynamic workspace creation to prevent data overwriting.
- **Automated Reporting:** Generates interactive HTML dashboards and R-based publication visuals.

---

## 🛠 System Architecture


1. **Preprocessing (C++):** Column-by-column stream processing to maintain flat memory usage.
2. **Feature Engineering:** Automated medical interaction feature generation (BMI, Pulse Pressure).
3. **Training (Python):** Stratified 5-Fold Cross-Validation with Optuna hyperparameter tuning.
4. **Ensembling:** Final submission generated via a weighted probability blender.

---

## 💻 Installation & Usage

### 1. Environment Setup
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cat << 'EOF' > README.md
# 🧬 BioBeat-Smoker-Status-Prediction
### Hybrid C++ / Python / R Machine Learning Engine

A universally adaptable, high-performance pipeline for tabular data prediction. Originally designed for the Kaggle Smoker Status competition, this engine utilizes a C++ core for numerical efficiency and an ensemble of 11 models for predictive power.

---

## 🚀 Key Features
- **Hybrid Performance:** C++11 Engine for memory-safe cleaning and scaling (O3 optimization).
- **Ensemble Gauntlet:** Automatically trains and compares 11 architectures:
  - *Tree-based:* XGBoost, Random Forest, GBM, ExtraTrees.
  - *Deep Learning:* PyTorch MLP, TabNet (Google), FT-Transformer (BERT-style).
  - *Statistical:* Logistic Regression, Naive Bayes, SVM, Ridge.
- **Auto-Schema Validation:** Ensures `train` and `test` compatibility before execution.
- **Session Isolation:** Dynamic workspace creation to prevent data overwriting.
- **Automated Reporting:** Generates interactive HTML dashboards and R-based publication visuals.

---

## 🛠 System Architecture


1. **Preprocessing (C++):** Column-by-column stream processing to maintain flat memory usage.
2. **Feature Engineering:** Automated medical interaction feature generation (BMI, Pulse Pressure).
3. **Training (Python):** Stratified 5-Fold Cross-Validation with Optuna hyperparameter tuning.
4. **Ensembling:** Final submission generated via a weighted probability blender.

---

## 💻 Installation & Usage

### 1. Environment Setup
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cat << 'EOF' >> README.md
### 2. Compile C++ Core
```bash
make build
# To run the default Smoker Status project
make run

# To launch the Universal Web UI
streamlit run app.py
cat << 'EOF' > src/python_scripts/main_full_run.py
import os
import sys
import pandas as pd
import importlib
from visualization.profiling import generate_data_profile
from training.compare_models import compare_all_models
from training.blender import blend_submissions
from visualization.dashboard import generate_html_report

def run_all_and_report():
    print("🚀 Starting BioBeat Universal Pipeline...")
    parquet_path = "data/processed/train.parquet"
    output_viz = "data/processed/visualizations"
    output_subs = "data/processed/submissions"
    
    df = pd.read_parquet(parquet_path)
    target = 'smoking' # This can be dynamic in app.py

    # 1. Generate Scientific Data Profile
    print("📈 Generating Data Profile...")
    generate_data_profile(df, target, f"{output_viz}/profiling")

    # 2. Run Model Gauntlet
    y = df[target].values
    X = df.drop(columns=[target]).values
    comparison_df = compare_all_models(X, y)
    
    # 3. Finalize and Blend
    blend_submissions(output_subs, f"{output_subs}/blended_final_submission.csv")
    
    # 4. Generate Report
    generate_html_report(comparison_df, "data/processed/model_report.html")
    print("✅ Done. View results in data/processed/model_report.html")

if __name__ == "__main__":
    run_all_and_report()
