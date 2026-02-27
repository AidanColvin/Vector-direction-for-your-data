import streamlit as st
import os
import uuid
import shutil
import subprocess
from file_io.header_parser import detect_target_column

st.set_page_config(page_title="BioBeat Universal Engine", layout="wide")

st.title("BioBeat Universal ML Engine")
st.write("This engine adapts to any tabular dataset. Upload your files to create an isolated workspace.")

# Create a unique session workspace
if 'session_id' not in st.session_state:
    st.session_state.session_id = str(uuid.uuid4())[:8]

workspace = f"workspaces/session_{st.session_state.session_id}"
os.makedirs(f"{workspace}/raw", exist_ok=True)
os.makedirs(f"{workspace}/processed", exist_ok=True)

train_file = st.file_uploader("Upload Training Data", type=['csv'])
test_file = st.file_uploader("Upload Testing Data", type=['csv'])

if st.button("🚀 RUN UNIVERSAL PIPELINE"):
    if train_file and test_file:
        # 1. Save to isolated workspace
        train_path = f"{workspace}/raw/train.csv"
        test_path = f"{workspace}/raw/test.csv"
        
        with open(train_path, "wb") as f: f.write(train_file.getbuffer())
        with open(test_path, "wb") as f: f.write(test_file.getbuffer())
        
        target = detect_target_column(train_path)
        st.info(f"Detected Target Column: **{target}**")

        # 2. Run Engine in Sandbox mode
        # We pass the workspace path to our main script
        with st.spinner("Executing 11-Model Gauntlet in isolated sandbox..."):
            cmd = ["python3", "src/python_scripts/main_full_run.py", 
                   "--input", train_path, 
                   "--output_dir", f"{workspace}/processed",
                   "--target", target]
            subprocess.run(cmd, check=True)
            
        st.success("Analysis Complete!")
        # 3. Provide download of the report from the sandbox
        with open(f"{workspace}/processed/model_report.html", "rb") as f:
            st.download_button("Download Sandbox Report", f, "BioBeat_Report.html")
    else:
        st.error("Missing files.")
