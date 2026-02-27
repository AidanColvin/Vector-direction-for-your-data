import streamlit as st
import os
import uuid
import subprocess
import shutil
from file_io.header_parser import detect_target_column
from file_io.schema_check import validate_schemas

def create_zip_archive(workspace_path, output_zip):
    """
    Creates a ZIP archive of the results.
    Includes the report, submissions, and visualizations.
    """
    results_path = os.path.join(workspace_path, "processed")
    if os.path.exists(results_path):
        shutil.make_archive(output_zip.replace('.zip', ''), 'zip', results_path)
        return True
    return False

st.set_page_config(page_title="Vector | Direction for your data...", layout="wide")

st.markdown("<h1 style='text-align: center; color: #38bdf8;'>Vector</h1>", unsafe_allow_html=True)
st.markdown("<p style='text-align: center; font-style: italic; color: #94a3b8;'>Direction for your data...</p>", unsafe_allow_html=True)
st.markdown("---")

if 'session_id' not in st.session_state:
    st.session_state.session_id = str(uuid.uuid4())[:8]

workspace = f"workspaces/session_{st.session_state.session_id}"
os.makedirs(f"{workspace}/raw", exist_ok=True)
os.makedirs(f"{workspace}/processed", exist_ok=True)

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

    train_file = next((f for f in uploaded_files if "train" in f.name.lower()), None)
    test_file = next((f for f in uploaded_files if "test" in f.name.lower()), None)

    if train_file and test_file:
        train_path = os.path.join(workspace, "raw", train_file.name)
        test_path = os.path.join(workspace, "raw", test_file.name)
        target = detect_target_column(train_path)
        
        if st.button("🚀 EXECUTE VECTOR GAUNTLET"):
            with st.spinner("Processing..."):
                try:
                    # Run the pipeline using the workspace paths
                    subprocess.run(["make", "build"], check=True)
                    subprocess.run(["python3", "src/python_scripts/run_preprocessing.py"], check=True)
                    subprocess.run(["python3", "src/python_scripts/main_full_run.py"], check=True)
                    
                    st.success("✅ Analysis Complete.")
                    
                    # Create and provide the Download All button
                    zip_name = f"Vector_Results_{st.session_state.session_id}.zip"
                    if create_zip_archive(workspace, zip_name):
                        with open(zip_name, "rb") as f:
                            st.download_button(
                                label="📦 DOWNLOAD ALL RESULTS (ZIP)",
                                data=f,
                                file_name=zip_name,
                                mime="application/zip"
                            )
                except Exception as e:
                    st.error(f"Engine Error: {e}")
