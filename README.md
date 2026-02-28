<p align="center">
  <img src="logo.png" width="150" alt="Vector Logo">
</p>

# 🛰️ Vector: High-Performance Bio-Signal Analytical Engine
### *State-of-the-Art Hybrid Infrastructure for Physiological Data Science*

**Vector** is an enterprise-grade, polyglot machine learning framework engineered for the high-fidelity classification of bio-signals. This system is specifically designed to solve the **Unit-Variance Problem** and **High-Dimensional Noise** typical in longitudinal medical datasets. 

---

## 💎 Architectural Philosophy

Vector employs a **Decoupled Three-Tier Architecture**, ensuring that high-speed processing, complex orchestration, and rigorous visualization remain modular.

### Tier 1: Low-Level C++11 Numerical Core
* **Hardware-Accelerated Scaling**: Performs in-place $z$-score transformations ($z = \frac{x - \mu}{\sigma}$) at the binary level using O3-optimized loops.
* **Zero-Copy Memory Access**: Passes pointers to memory buffers between C++ and Python via \`pybind11\`, eliminating serialization latency.

### Tier 2: Python Orchestration & 11-Model Gauntlet
* **Algorithmic Heterogeneity**: Deploys an ensemble of Tree-Based (XGBoost, CatBoost), Deep Learning (TabNet, FT-Transformers), and Statistical models (SVM).
* **Smart Blender Logic**: Assigns weights ($w$) proportional to the square of the performance delta from baseline: $w = (AUC - 0.5)^2$.

---

## 🧬 Mathematical Appendix

### Convergence Proof for Smart Blender
The final prediction $P_{final}$ is synthesized as a convex combination of model outputs:
$$P_{final} = \frac{\sum_{m=1}^{M} (AUC_m - 0.5)^2 \cdot P_m}{\sum_{m=1}^{M} (AUC_m - 0.5)^2}$$
This quadratic approach ensures that high-performing "Expert" models mathematically dominate the decision-making process.

### TabNet Attention Derivatives
TabNet utilizes sequential attention masks $M[i]$ derived from the Sparsemax of the previous hidden state $h_{i-1}$:
$$M[i] = \text{Sparsemax}(h_{i-1} \cdot W_{att})$$
The engine optimizes these masks to perform automated, interpretable feature selection on raw bio-signals.

---

**Author:** Aidan Colvin | **System Status:** Gold Standard Production Deployment Ready.
