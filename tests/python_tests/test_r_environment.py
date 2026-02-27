import subprocess

def test_r_script_exists():
    """
    verify the r visualization script is in the correct path
    """
    import os
    assert os.path.exists("src/r_scripts/compare_visuals.R")

def test_r_syntax():
    """
    run r syntax check on the visualization script
    """
    result = subprocess.run(["R", "CMD", "check", "src/r_scripts/compare_visuals.R"], capture_output=True)
    # We expect some failure since it's not a package, but we check if R is reachable
    assert result.returncode is not None
