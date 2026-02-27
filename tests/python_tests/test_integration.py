import subprocess
import os

def test_cpp_build():
    """
    verifies that the c++ engine compiles 
    and generates the .so library files
    """
    result = subprocess.run(["make", "build"], capture_output=True)
    assert result.returncode == 0
    
    # Check if files exist (on Mac they end in .so or .cpython-xxx-darwin.so)
    files = os.listdir("src/cpp_engine")
    so_files = [f for f in files if f.endswith(".so")]
    assert len(so_files) >= 1
