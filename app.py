import streamlit as st
import os
import sys
import uuid
import subprocess
import shutil

# Critical Path Configuration
current_dir = os.path.dirname(os.path.abspath(__file__))
scripts_path = os.path.join(current_dir, "src", "python_scripts")
if scripts_path not in sys.path:
    sys.path.append(scripts_path)

from file_io.header_parser import detect_target_column
from file_io.schema_check import validate_schemas

st.set_page_config(page_title="Vector | Direction for your data", layout="wide")

st.markdown("<h1 style='text-align: center; color: #38bdf8;'>Vector</h1>", unsafe_allow_html=True)
st.markdown("<p style='text-align: center; font-style: italic; color: #94a3b8;'>Direction for your data...</p>", unsafe_allow_html=True)
st.markdown("---")

if 'session_id' not in st.session_state:
    st.session_state.session_id = str(uuid.uuid4())[:8]

workspace = f"workspaces/session_{st.session_state.session_id}"
os.makedirs(f"{workspace}/raw", exist_ok=True)
os.makedirs(f"{workspace}/processed", exist_ok=True)

st.write("### Load Data")
uploaded_files = st.file_uploader(
    "Drag and drop 1-3 files here, or click to browse", 
    type=['csv', 'tsv', 'parquet'], 
    accept_multiple_files=True
)

if uploaded_files:
    st.write("#### Manifest")
    for uploaded_file in uploaded_files:
        st.info("File Detected: " + uploaded_file.name)
        file_path = os.path.join(workspace, "raw", uploaded_file.name)
        with open(file_path, "wb") as f:
            f.write(uploaded_file.getbuffer())

    train_file = next((f for f in uploaded_files if "train" in f.name.lower()), None)
    test_file = next((f for f in uploaded_files if "test" in f.name.lower()), None)

    if train_file and test_file:
        if st.button("RUN VECTOR ENGINE"):
            with st.spinner("Processing..."):
                try:
                    subprocess.run(["make", "build"], check=True)
                    subprocess.run(["python3", "src/python_scripts/run_preprocessing.py"], check=True)
                    subprocess.run(["python3", "src/python_scripts/main_full_run.py"], check=True)
                    st.success("Analysis Complete.")
                    
                    zip_name = f"Vector_Results_{st.session_state.session_id}"
                    shutil.make_archive(zip_name, 'zip', "data/processed")
                    
                    with open(f"{zip_name}.zip", "rb") as f:
                        st.download_button(
                            label="DOWNLOAD ALL RESULTS (ZIP)",
                            data=f,
                            file_name=f"{zip_name}.zip",
                            mime="application/zip"
                        )
                except Exception as e:
                    st.error("Engine Error: " + str(e))
    else:
        st.warning("Upload both train and test files to begin.")

st.markdown("---")
st.caption("Vector Hybrid Engine | Secure Session: " + st.session_state.session_id)
