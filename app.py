import streamlit as st
import os
import uuid
import subprocess
from file_io.header_parser import detect_target_column
from file_io.schema_check import validate_schemas

st.set_page_config(page_title="BioBeat Universal Engine", layout="wide")

st.title("Vector | Direction for your data...")
st.markdown("---")

if 'session_id' not in st.session_state:
    st.session_state.session_id = str(uuid.uuid4())[:8]

workspace = f"workspaces/session_{st.session_state.session_id}"
os.makedirs(f"{workspace}/raw", exist_ok=True)

col1, col2 = st.columns(2)
with col1:
    train_file = st.file_uploader("Upload Training Data", type=['csv'])
with col2:
    test_file = st.file_uploader("Upload Testing Data", type=['csv'])

if train_file and test_file:
    train_path = f"{workspace}/raw/train.csv"
    test_path = f"{workspace}/raw/test.csv"
    
    with open(train_path, "wb") as f: f.write(train_file.getbuffer())
    with open(test_path, "wb") as f: f.write(test_file.getbuffer())
    
    target = detect_target_column(train_path)
    
    # Perform Auto-Schema Check
    is_valid, message = validate_schemas(train_path, test_path, target)
    
    if is_valid:
        st.success(message)
        if st.button("🚀 RUN UNIVERSAL PIPELINE"):
            with st.spinner("Processing..."):
                # Execute full pipeline logic here
                st.write("Engine is running 11-model gauntlet...")
    else:
        st.error(f"⚠️ Schema Mismatch: {message}")
