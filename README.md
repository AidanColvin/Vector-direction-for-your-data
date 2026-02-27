# BioBeat: Smoker Status Prediction — Kaggle 

[![R](https://img.shields.io/badge/Language-R-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Competition](https://img.shields.io/badge/Kaggle-Playground%20S5E12-20BEFF?logo=kaggle&logoColor=white)](https://www.kaggle.com/competitions/playground-series-s5e12)
[![Models](https://img.shields.io/badge/Models-7%20Supervised%20ML-brightgreen)]()
[![Pipeline](https://img.shields.io/badge/Pipeline-5%20Steps-blue)]()

> A complete, end-to-end R pipeline for the Kaggle Playground Series S5E12 diabetes dataset — covering data cleaning, encoding, scaling, exploratory analysis, and feature extraction, followed by training, evaluating, and comparing **7 supervised machine learning models** with full visualization and table outputs for every model and a unified cross-model comparison layer.

---

## Table of Contents

1. [What This Does](#what-this-does)
2. [Architecture Overview](#architecture-overview)
3. [Preprocessing Pipeline](#preprocessing-pipeline)
4. [Modeling Layer](#modeling-layer)
5. [Visualizations & Tables](#visualizations--tables)
6. [Cross-Model Comparison](#cross-model-comparison)
7. [Repository Structure](#repository-structure)
8. [Quickstart](#quickstart)
9. [Configuration Reference](#configuration-reference)
10. [All Output Artifacts](#all-output-artifacts)
11. [Troubleshooting](#troubleshooting)
12. [Roadmap](#roadmap)
13. [License](#license)
14. [Citation](#citation)

---

## What This Does

This repository takes raw Kaggle competition CSVs and runs them through a full machine learning workflow — from raw tabular data to trained models, evaluated results, and publication-ready comparison outputs.

**Preprocessing** handles cleaning, encoding, and scaling with train/test consistency built in. **Modeling** trains 7 different supervised classifiers using stratified sampling, 3-fold cross-validation, and consistent evaluation logic. Every model produces its own set of charts and metric tables. A final comparison layer aggregates all results into overlay plots, scorecards, and side-by-side diagnostics.

The full workflow runs in a single command and targets a runtime under 10 minutes on a standard machine.

---

## Architecture Overview

```
data/raw/train.csv
data/raw/test.csv
        │
        ▼
┌──────────────────────────────────────────┐
│  PREPROCESSING PIPELINE  (5 steps)       │
│                                          │
│  1. Cleaning    → train/test_clean       │
│  2. Encoding    → train/test_encoded     │
│  3. Scaling     → train/test_standardized│
│  4. EDA         → stats + variance + RF  │
│  5. Features    → final vectors + log    │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│  MODELING LAYER  (7 models)              │
│                                          │
│  1. Logistic Regression                  │
│  2. Linear Regression                    │
│  3. Naive Bayes                          │
│  4. Random Forest                        │
│  5. Gradient Boosting (GBM)              │
│  6. XGBoost                              │
│  7. SVM (Radial)                         │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│  OUTPUTS (per model + cross-model)       │
│                                          │
│  • PNGs: ROC, confusion matrix,          │
│    calibration, feature importance,      │
│    tuning curves, model-specific plots   │
│  • CSVs: metrics, classification report, │
│    CV results, coefficients/importance   │
│  • Comparison: overlay plots, scorecard, │
│    dot plots, grid views                 │
└──────────────────────────────────────────┘
```

---

## Preprocessing Pipeline

The preprocessing pipeline runs in 5 ordered steps and is orchestrated through `scripts/run_steps.R` or the shell wrapper `scripts/run_pipeline.sh`. Each step is isolated and the runner catches failures without killing the session.

---

### Step 1 — Cleaning

**Script:** `src/pipelines/run_cleaning.R`  
**Inputs:** `data/raw/train.csv`, `data/raw/test.csv`  
**Outputs:** `data/processed/train_clean.csv`, `data/processed/test_clean.csv`

| Action | Detail |
|---|---|
| Missing value report | NA counts and blank string counts per column |
| Sentinel token report | Checks for `"Unknown"`, `"N/A"`, `"?"`, and empty strings |
| Type coercion | Converts numeric-like character columns to numeric where fully safe |
| Invalid value removal | Removes rows containing `Inf`, `-Inf`, or `NaN` in numeric columns |
| NA strategy | Configurable: `"drop"` removes rows with any NA; `"median"` imputes numeric columns |

---

### Step 2 — Encoding

**Script:** `src/pipelines/run_encoding.R`  
**Inputs:** `data/processed/train_clean.csv`, `data/processed/test_clean.csv`  
**Outputs:** `data/processed/train_encoded.csv`, `data/processed/test_encoded.csv`

| Action | Detail |
|---|---|
| Sentinel normalization | Replaces `"Unknown"`, `"N/A"`, `"NA"`, `"?"`, and blank strings with `NA` |
| Shared factor levels | Factor levels are derived from the union of train + test to prevent unseen-level errors at prediction time |
| Consistent ordering | Both datasets use identical factor level ordering |

---

### Step 3 — Scaling

**Script:** `src/pipelines/run_scaling.R`  
**Inputs:** `data/processed/train_encoded.csv`, `data/processed/test_encoded.csv`  
**Outputs:** `data/processed/train_standardized.csv`, `data/processed/test_standardized.csv`

| Action | Detail |
|---|---|
| Continuous column detection | Automatically excludes binary 0/1 flags, `id`, and `diagnosed_diabetes` |
| Train-only fitting | Mean and SD computed on train data only; zero-variance columns handled safely (SD set to 1) |
| Test transform | The same fitted parameters applied to test — no re-fitting on test data |
| Exclusion list | Configurable via `exclude = c("id", "diagnosed_diabetes")` |

---

### Step 4 — EDA (Memory-Safe)

**Script:** `src/pipelines/run_eda.R`  
**Input:** `data/processed/train_standardized.csv`

| Action | Detail |
|---|---|
| Row sampling | Samples up to `sample_n = 50000` rows by default to avoid memory limits on large datasets |
| Summary statistics | Per-column: n, mean, SD, min, p25, median, p75, max |
| Variance report | Variance per feature, sorted ascending; zero-variance columns are flagged |
| RF feature importance | Trains a 100-tree Random Forest on numeric predictors and writes importance scores. If `randomForest` is not installed, a stub file is written so downstream checks remain stable |

---

### Step 5 — Feature Extraction

**Script:** `src/pipelines/run_features.R`  
**Inputs:** `data/processed/train_standardized.csv`, `data/processed/test_standardized.csv`

| Action | Detail |
|---|---|
| Variable catalog | Classifies each column as: target, id, numeric, or categorical |
| Integer coding | Converts categoricals to integer codes — robust against single-level columns and avoids `model.matrix` contrast failures |
| Validation log | Pass/fail checks on row counts, target presence, and train/test column alignment |
| Final feature table | Train includes target; test does not |

---

## Modeling Layer

All 7 models are trained and evaluated in `generate_all_outputs.R`. The full workflow uses a stratified 30,000-row sample of the standardized training data, an 80/20 train/test split, and 3-fold cross-validation with AUC as the optimization metric.

Each model is wrapped in a `tryCatch` block — failures are logged and reported without stopping execution of other models. All trained model objects are saved as `.rds` files to the `models/` directory for later use.

---

### Model 1 — Logistic Regression

**Method:** `glm` with `family = "binomial"` via `caret`

The baseline linear classifier. Fits on the full feature set and produces coefficient estimates showing which predictors drive the binary outcome up or down. Serves as the interpretability anchor for the comparison.

**Unique outputs:** coefficient bar chart (positive/negative colored), coefficients CSV with estimates and standard errors.

---

### Model 2 — Linear Regression

**Method:** Standard `lm()` on a 0/1 numeric target

Fits a continuous linear model to the binary outcome. Used as a diagnostic reference: actual vs predicted scatter, residuals vs fitted, Q-Q plot, and scale-location plot provide a view of model assumptions and residual behavior that complements the classification models.

**Unique outputs:** actual vs predicted scatter, residuals vs fitted, Q-Q plot, scale-location plot, RMSE and R² metrics.

---

### Model 3 — Naive Bayes

**Method:** `naive_bayes` via `caret`, tuned over `usekernel` and `laplace`

A probabilistic classifier assuming feature independence. The prior probability plot shows observed class balance and the tuning grid shows how kernel smoothing and Laplace correction affect cross-validated AUC.

**Unique outputs:** prior probability bar chart, tuning results chart comparing AUC across kernel/laplace combinations.

---

### Model 4 — Random Forest

**Method:** `rf` via `caret`, `ntree = 100`, tuned over 2 `mtry` values

An ensemble of 100 decision trees. Provides mean decrease Gini feature importance, an OOB error curve showing how error evolves as trees are added, and an mtry tuning chart.

**Unique outputs:** feature importance bar chart, OOB error curve, mtry tuning chart, OOB error by trees CSV.

---

### Model 5 — Gradient Boosting (GBM)

**Method:** `gbm` via `caret`, grid over `n.trees = c(100, 150)` with `interaction.depth = 2, shrinkage = 0.1`

A sequential boosting ensemble. Produces relative influence feature importance and a learning curve showing training loss across boosting iterations.

**Unique outputs:** feature importance bar chart, learning curve, tuning surface comparing AUC at different tree counts, boosting log CSV.

---

### Model 6 — XGBoost

**Method:** `xgbTree` via `caret`, fixed grid: `nrounds = 100, max_depth = 4, eta = 0.1, colsample_bytree = 0.8, subsample = 0.8`

A regularized gradient boosting implementation. Produces gain-based feature importance and a gain vs cover scatter plot highlighting which features contribute both high predictive lift and broad coverage across training data.

**Unique outputs:** gain-based feature importance bar chart, gain vs cover scatter plot.

---

### Model 7 — SVM (Radial Kernel)

**Method:** `svmRadial` via `caret`, fixed grid: `C = 1, sigma = 0.01`

A support vector machine with a radial basis function kernel for non-linear decision boundaries.

**Unique outputs:** cost parameter tuning chart, best hyperparameters CSV.

---

## Visualizations & Tables

Every model writes its outputs to dedicated subdirectories:

```
data/processed/
├── visualizations/
│   ├── logistic_regression/
│   ├── linear_regression/
│   ├── naive_bayes/
│   ├── random_forest/
│   ├── gradient_boosting/
│   ├── xgboost/
│   ├── svm/
│   └── comparison/
└── tables/
    ├── logistic_regression/
    ├── linear_regression/
    ├── naive_bayes/
    ├── random_forest/
    ├── gradient_boosting/
    ├── xgboost/
    ├── svm/
    └── comparison/
```

### Standard outputs for every classification model

| Output | Description |
|---|---|
| `roc_curve.png` | ROC curve with AUC annotated in subtitle |
| `confusion_matrix.png` | Heatmap-style confusion matrix with cell counts |
| `calibration_curve.png` | Predicted probability vs fraction positive across 10 bins |
| `metrics.csv` | AUC, Accuracy, Precision, Recall, F1, Kappa |
| `classification_report.csv` | Full caret `byClass` metrics |
| `cv_results.csv` | Cross-validation fold results from caret |

### Model-specific additional outputs

| Model | Additional Outputs |
|---|---|
| Logistic Regression | `coefficients.png`, `coefficients.csv` |
| Linear Regression | `actual_vs_predicted.png`, `residuals_vs_fitted.png`, `qq_plot.png`, `scale_location.png`, `coefficients.png/.csv`, `predictions.csv` |
| Naive Bayes | `prior_probabilities.png/.csv`, `tuning_results.png` |
| Random Forest | `feature_importance.png/.csv`, `oob_error_curve.png`, `tuning_mtry.png`, `oob_error_by_trees.csv` |
| Gradient Boosting | `feature_importance.png/.csv`, `learning_curve.png`, `tuning_surface.png`, `boosting_log.csv` |
| XGBoost | `feature_importance.png/.csv`, `gain_vs_cover.png` |
| SVM | `tuning_C_sigma.png`, `best_hyperparameters.csv` |

---

## Cross-Model Comparison

After all models complete, a comparison layer aggregates every result into a unified set of cross-model outputs saved to `data/processed/visualizations/comparison/` and `data/processed/tables/comparison/`.

| Output | Description |
|---|---|
| `roc_overlay.png` | All ROC curves on one chart, each labelled with AUC |
| `bar_auc.png` | Horizontal bar chart: AUC per model, sorted |
| `bar_accuracy.png` | Horizontal bar chart: Accuracy per model |
| `bar_f1.png` | Horizontal bar chart: F1 per model |
| `bar_precision.png` | Horizontal bar chart: Precision per model |
| `bar_recall.png` | Horizontal bar chart: Recall per model |
| `confusion_matrix_grid.png` | All confusion matrices in one faceted grid (3 columns) |
| `metric_dot_plot.png` | All models × all metrics as a dot plot, faceted by metric |
| `calibration_overlay.png` | All calibration curves overlaid on one chart |
| `master_scorecard.csv` | One row per model: AUC, Accuracy, Precision, Recall, F1, Kappa |

A final summary table is printed to the console at the end of the run showing PNG and CSV counts written per model.

---

## Repository Structure

```
.
├── data/
│   ├── raw/                              # Kaggle input files (train.csv, test.csv)
│   └── processed/                        # All generated outputs
│       ├── visualizations/               # PNGs organized by model
│       └── tables/                       # CSVs organized by model
│
├── models/                               # Saved .rds model objects (one per model)
│
├── src/
│   ├── pipelines/                        # Top-level step runners
│   │   ├── run_cleaning.R
│   │   ├── run_encoding.R
│   │   ├── run_scaling.R
│   │   ├── run_eda.R
│   │   └── run_features.R
│   ├── checks/                           # Syntax, source, and output validation scripts
│   │   ├── check_pipeline_outputs.R
│   │   ├── check_script_syntax.R
│   │   └── check_sources.R
│   ├── cleaning/                         # Missing value checks, type coercion, invalid removal
│   ├── encoding/                         # Sentinel normalization, factor encoding, one-hot helpers
│   ├── eda/                              # Variance report, trend analysis, RF importance
│   ├── evaluation/                       # Cross-model comparison visualizations
│   ├── features/                         # Feature categorization, extraction, validation
│   ├── io/                               # CSV load/write helpers
│   ├── models/                           # Extensible model training modules
│   ├── resampling/                       # Cross-validation and bootstrap trainControl builders
│   ├── scaling/                          # Scaler fit, apply, and continuous column detection
│   └── legacy/                           # Archived older versions
│
├── scripts/
│   ├── run_steps.R                       # Safe step runner with timing and pass/fail summary
│   └── run_pipeline.sh                   # Shell wrapper that logs every run
│
├── generate_all_outputs.R                # Full modeling run: all 7 models + comparison
├── main.R                                # Minimal entrypoint (preprocessing steps 1–3 only)
├── Makefile                              # Optional make targets for common commands
├── requirements.R                        # Base package installs
└── README.md
```

---

## Quickstart

### Prerequisites

- R ≥ 4.1.0
- `bash` (for the shell wrapper)
- Kaggle account with access to the competition data

---

### 1. Clone the repository

```bash
git clone https://github.com/AidanColvin/diabetes-prediction.git
cd diabetes-prediction
```

---

### 2. Add the competition data

Download from the [Kaggle competition page](https://www.kaggle.com/competitions/playground-series-s5e12) and place the files at:

```
data/raw/train.csv
data/raw/test.csv
```

Or use the Kaggle CLI:

```bash
kaggle competitions download -c playground-series-s5e12 -p data/raw/
unzip data/raw/playground-series-s5e12.zip -d data/raw/
```

---

### 3. Install R dependencies

```bash
Rscript requirements.R
```

The following packages are required for the full modeling run:

```
caret, readr, dplyr, ggplot2, pROC, tidyr,
randomForest, e1071, gbm, naivebayes, xgboost
```

---

### 4. Run the preprocessing pipeline

```bash
bash scripts/run_pipeline.sh
```

Runs all 5 preprocessing steps in order, prints timing per step, and writes a timestamped log.

---

### 5. Run all models and generate all outputs

```bash
Rscript generate_all_outputs.R
```

Runs preprocessing, trains all 7 models, and generates every visualization and table. Target runtime is under 10 minutes.

Example console output at completion:

```
══════════════════════════════════════════════════════
  Model                     PNG   CSV
  logistic_regression         4     4
  linear_regression           5     3
  naive_bayes                 4     4
  random_forest               5     5
  gradient_boosting           5     5
  xgboost                     4     4
  svm                         4     4
  comparison                  9     1
──────────────────────────────────────────────────────
  TOTAL RUNTIME: 8.4 minutes

FINAL SCORECARD:
  model                  AUC   Accuracy   Precision   Recall     F1   Kappa
  Logistic Regression    ...
  ...
══════════════════════════════════════════════════════
```

---

### 6. Minimal run (preprocessing steps 1–3 only)

```bash
Rscript main.R
```

---

### 7. Run the built-in validation checks

```bash
Rscript src/checks/check_pipeline_outputs.R
Rscript src/checks/check_script_syntax.R
Rscript src/checks/check_sources.R
```

---

## Configuration Reference

### Missing-data strategy

Edit in `scripts/run_steps.R`:

```r
# Drop any row containing NA (default)
run_cleaning_pipeline(na_strategy = "drop")

# Impute numeric columns with column median
run_cleaning_pipeline(na_strategy = "median")
```

---

### Scaling exclusions

Edit in `scripts/run_steps.R`:

```r
# Default
run_scaling_pipeline(exclude = c("id", "diagnosed_diabetes"))

# Exclude additional columns from standardization
run_scaling_pipeline(exclude = c("id", "diagnosed_diabetes", "smoking_history"))
```

---

### EDA sampling size

Edit in `src/pipelines/run_eda.R`:

```r
# Default: 50,000 rows
run_eda_pipeline(sample_n = 50000)

# Full dataset (requires sufficient RAM)
run_eda_pipeline(sample_n = Inf)
```

---

### Modeling sample size

Edit in `generate_all_outputs.R`:

```r
# Default: 30,000 stratified rows
s_idx <- createDataPartition(raw$diagnosed_diabetes, p = 30000 / nrow(raw), list = FALSE)
```

Change `30000` to any integer to adjust the training sample size.

---

### Cross-validation folds

Edit in `generate_all_outputs.R`:

```r
# Default: 3-fold CV (fast)
cv3 <- trainControl(method = "cv", number = 3, ...)

# Increase to 5-fold for more robust estimates (longer runtime)
cv3 <- trainControl(method = "cv", number = 5, ...)
```

---

## All Output Artifacts

### Preprocessing (`data/processed/`)

| File | Step |
|---|---|
| `train_clean.csv` / `test_clean.csv` | Cleaning |
| `train_encoded.csv` / `test_encoded.csv` | Encoding |
| `train_standardized.csv` / `test_standardized.csv` | Scaling |
| `eda_statistical_trends_summary.csv` | EDA |
| `eda_feature_variance_report.csv` | EDA |
| `eda_rf_feature_impact_scores.csv` | EDA |
| `features_categorized_variables.csv` | Features |
| `features_validation_pass_fail_log.csv` | Features |
| `features_final_extracted_vectors.csv` | Features |

---

### Saved model objects (`models/`)

| File | Model |
|---|---|
| `logistic_regression.rds` | Logistic Regression |
| `linear_regression.rds` | Linear Regression |
| `naive_bayes.rds` | Naive Bayes |
| `random_forest.rds` | Random Forest |
| `gradient_boosting.rds` | Gradient Boosting |
| `xgboost.rds` | XGBoost |
| `svm.rds` | SVM |

Load any saved model with:

```r
m <- readRDS("models/xgboost.rds")
predictions <- predict(m, new_data, type = "prob")
```

---

## Troubleshooting

### `"Missing input: data/processed/train_standardized.csv"`

EDA or feature extraction ran before scaling completed. Run the full pipeline in order:

```bash
bash scripts/run_pipeline.sh
```

---

### A model step prints `✗ FAILED` but others continue

All model blocks are wrapped in `tryCatch`. A failure in one model does not stop others. Check the printed error message. Common causes are a missing package or a column name mismatch after preprocessing changes.

---

### Random Forest importance file is empty

Expected when `randomForest` is not installed. A stub file is written so downstream checks pass. Install and re-run:

```r
install.packages("randomForest")
Rscript -e "source('src/pipelines/run_eda.R'); run_eda_pipeline()"
```

---

### Total runtime is longer than expected

The default 30,000-row sample and 3-fold CV target under 10 minutes. If runtime is excessive, check whether `ntree` in the Random Forest block has been increased above 100, or whether CV folds have been raised above 3.

---

### Factor level error during encoding or modeling

Confirm that `run_encoding_pipeline()` calls `encode_common_categoricals()` with both `train_df` and `test_df` in the same call. Encoding them separately bypasses the shared-level union logic and can produce mismatched factor levels at prediction time.

---

### Pipeline passes but outputs look wrong

Use the two audit files for fast diagnostic signals:

```
data/processed/features_validation_pass_fail_log.csv   ← schema, NA rates, column alignment
data/processed/eda_statistical_trends_summary.csv      ← distributions, suspicious values
```

Run the built-in checks:

```bash
Rscript src/checks/check_pipeline_outputs.R
Rscript src/checks/check_script_syntax.R
Rscript src/checks/check_sources.R
```

---

## Roadmap

- [ ] Submission file generation — Kaggle-formatted predictions on the competition test set
- [ ] Hyperparameter tuning expansion — broader grids for RF, GBM, XGBoost, and SVM
- [ ] SHAP value integration — model-agnostic feature importance explanations
- [ ] Three-way train/validation/test split — stricter leakage prevention for final evaluation
- [ ] GitHub Actions CI — syntax check and dry-run on every push
- [ ] HTML report generation — single-file summary of all model results and plots

---

## License

This project is licensed under the **MIT License**. See [`LICENSE`](LICENSE) for full terms.

---

## Citation

```bibtex
@misc{colvin2025diabetes,
  author       = {Colvin, Aidan},
  title        = {Diabetes Prediction — Kaggle Playground Series S5E12},
  year         = {2025},
  publisher    = {GitHub},
  howpublished = {\url{https://github.com/AidanColvin/diabetes-prediction}},
  note         = {End-to-end R preprocessing and supervised ML pipeline}
}
```

Competition reference: [Kaggle Playground Series S5E12](https://www.kaggle.com/competitions/playground-series-s5e12)
