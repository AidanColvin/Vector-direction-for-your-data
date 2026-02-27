import streamlit as st
import os
import sys
import uuid
import subprocess
import shutil

# 1. Add internal scripts to the Python path so imports work
current_dir = os.path.dirname(os.path.abspath(__file__))
scripts_path = os.path.join(current_dir, "src", "python_scripts")
if scripts_path not in sys.path:
    sys.path.append(scripts_path)

# 2. Now import your custom modules
from file_io.header_parser import detect_target_column
from file_io.schema_check import validate_schemas

# Page Setup
st.set_page_config(page_title="Vector | Direction for your data", layout="wide")
st.markdown("<h1 style='text-align: center; color: #38bdf8;'>Vector</h1>", unsafe_allow_html=True)
st.markdown("<p style='text-align: center; font-style: italic; color: #94a3b8;'>Direction for your data...</p>", unsafe_allow_html=True)
st.markdown("---")

# Session & Workspace Management
if 'session_id' not in st.session_state:
    st.session_state.session_id = str(uuid.uuid4())[:8]

workspace = f"workspaces/session_{st.session_state.session_id}"
os.makedirs(f"{workspace}/raw", exist_ok=True)
os.makedirs(f"{workspace}/processed", exist_ok=True)

# 3. Enhanced File Loading
st.write("### 📥 Load Data")
uploaded_files = st.file_uploader(
    "Drag and Drop 1-3 Files (Train, Test, Sample)", 
    type=['csv', 'tsv'], 
    accept_multiple_files=True
)

if uploaded_files:
    for uploaded_file in uploaded_files:
        file_path = os.path.join(workspace, "raw", uploaded_file.name)
        with open(file_path, "wb") as f:
            f.write(uploaded_file.getbuffer())
        st.info(f"📄 **Detected:** {uploaded_file.name}")

    train_file = next((f for f in uploaded_files if "train" in f.name.lower()), None)
    test_file = next((f for f in uploaded_files if "test" in f.name.lower()), None)

    if train_file and test_file:
        train_path = os.path.join(workspace, "raw", train_file.name)
        test_path = os.path.join(workspace, "raw", test_file.name)
        target = detect_target_column(train_path)
        
        # 4. Execute Pipeline
        if st.button("🚀 EXECUTE VECTOR GAUNTLET"):
            with st.spinner("Executing Pipeline..."):
                try:
                    # Build C++ and Run Analysis
                    subprocess.run(["make", "build"], check=True)
                    subprocess.run(["python3", "src/python_scripts/run_preprocessing.py"], check=True)
                    subprocess.run(["python3", "src/python_scripts/main_full_run.py"], check=True)
                    
                    st.success("✅ Analysis Complete.")
                    
                    # 5. Result Management & Download All
                    zip_name = f"Vector_Results_{st.session_state.session_id}"
                    shutil.make_archive(zip_name, 'zip', "data/processed")
                    
                    with open(f"{zip_name}.zip", "rb") as f:
                        st.download_button(
                            label="📦 DOWNLOAD ALL RESULTS (ZIP)",
                            data=f,
                            file_name=f"{zip_name}.zip",
                            mime="application/zip"
                        )
                except Exception as e:
                    st.error(f"Engine Error: {e}")
