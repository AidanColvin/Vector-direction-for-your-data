import streamlit as st
import os
import uuid
import subprocess
from file_io.header_parser import detect_target_column
from file_io.schema_check import validate_schemas

# Page Branding
st.set_page_config(page_title="Vector | Direction for your data...", layout="wide")

st.markdown("<h1 style='text-align: center; color: #38bdf8;'>Vector</h1>", unsafe_allow_html=True)
st.markdown("<p style='text-align: center; font-style: italic; color: #94a3b8;'>Direction for your data...</p>", unsafe_allow_html=True)
st.markdown("---")

if 'session_id' not in st.session_state:
    st.session_state.session_id = str(uuid.uuid4())[:8]

workspace = f"workspaces/session_{st.session_state.session_id}"
os.makedirs(f"{workspace}/raw", exist_ok=True)

# THE DROP ZONE
st.write("### 📥 Load Data")
uploaded_files = st.file_uploader(
    "Drag and Drop 1-3 Files (Train, Test, Sample)", 
    type=['csv', 'tsv'], 
    accept_multiple_files=True
)

if uploaded_files:
    st.write("---")
    st.write("#### 🛰️ Files Detected in Console:")
    
    # Display file names and handle storage
    for uploaded_file in uploaded_files:
        st.info(f"📄 **File:** {uploaded_file.name} | **Size:** {uploaded_file.size / 1024:.2f} KB")
        
        # Save to sandbox
        file_path = os.path.join(workspace, "raw", uploaded_file.name)
        with open(file_path, "wb") as f:
            f.write(uploaded_file.getbuffer())

    # Automated logic to identify which file is which
    train_file = next((f for f in uploaded_files if "train" in f.name.lower()), None)
    test_file = next((f for f in uploaded_files if "test" in f.name.lower()), None)

    if train_file and test_file:
        train_path = os.path.join(workspace, "raw", train_file.name)
        test_path = os.path.join(workspace, "raw", test_file.name)
        
        target = detect_target_column(train_path)
        is_valid, message = validate_schemas(train_path, test_path, target)

        if is_valid:
            st.success(f"✅ Schema Verified for {target}. Direction set.")
            if st.button("🚀 EXECUTE VECTOR GAUNTLET"):
                with st.spinner("Processing Hybrid C++ & 11-Model Ensemble..."):
                    # Execute Pipeline...
                    st.write("Running...")
        else:
            st.error(f"⚠️ {message}")
    elif len(uploaded_files) > 0:
        st.warning("Please ensure you have uploaded both a 'train' and 'test' file to begin.")

st.markdown("---")
st.caption("Vector Hybrid Engine | Secure Sandbox Mode")
