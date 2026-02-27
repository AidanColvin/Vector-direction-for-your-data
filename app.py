import streamlit as st
import os
import subprocess
import zipfile
from pathlib import Path

st.set_page_config(page_title="BioBeat: Smoker Status Prediction", layout="wide")

st.title("BioBeat: Smoker Status Prediction")
st.markdown("### End-to-End Supervised ML & Deep Learning Pipeline")
st.write("Upload your Kaggle dataset files below to run the 11-model gauntlet.")

# Styling the drop box with rounded corners
st.markdown("""
    <style>
    .stFileUploader {
        border: 2px dashed #276DC3;
        border-radius: 15px;
        padding: 20px;
    }
    </style>
    """, unsafe_allow_html=True)

col1, col2, col3 = st.columns(3)
with col1:
    train_file = st.file_uploader("Upload train.csv", type=['csv'])
with col2:
    test_file = st.file_uploader("Upload test.csv", type=['csv'])
with col3:
    sample_file = st.file_uploader("Upload sample_submission.csv", type=['csv'])

if st.button("🚀 GO - Run Full Pipeline"):
    if train_file and test_file:
        with st.spinner("Running C++ Preprocessing & 11 Model Training..."):
            # 1. Save uploaded files
            os.makedirs("data/raw", exist_ok=True)
            with open("data/raw/train.csv", "wb") as f: f.write(train_file.getbuffer())
            with open("data/raw/test.csv", "wb") as f: f.write(test_file.getbuffer())
            
            # 2. Run the pipeline via subprocess
            subprocess.run(["make", "build"], check=True)
            subprocess.run(["make", "run"], check=True)
            
            st.success("Analysis Complete!")
            
            # 3. Provide Downloads
            with open("data/processed/model_report.html", "rb") as f:
                st.download_button("Download Full HTML Report", f, "BioBeat_Report.html")
                
            # Zip the submissions
            with zipfile.ZipFile("submissions.zip", "w") as z:
                for root, dirs, files in os.walk("data/processed/submissions"):
                    for file in files:
                        z.write(os.path.join(root, file), file)
            
            with open("submissions.zip", "rb") as f:
                st.download_button("Download All Submission CSVs", f, "submissions.zip")
    else:
        st.error("Please upload both train and test files.")
