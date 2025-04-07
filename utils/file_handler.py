import os
import re
from urllib.parse import urlparse

def sanitize_filename(name):
    """Removes or replaces characters that are problematic in filenames."""
    # Remove protocol (http://, https://)
    name = re.sub(r'^https?://', '', name)
    # Replace common problematic characters with underscores
    name = re.sub(r'[\\/*?:"<>|]', '_', name)
    # Replace periods if they are not part of a valid domain/IP structure
    # (This is a simple approach, might need refinement for complex cases)
    if not re.match(r'^[\w\.-]+$', name): # Basic check if it looks like domain/IP
         name = name.replace('.', '_')
    # Avoid names starting or ending with spaces or dots
    name = name.strip(' .')
    # Limit length (optional)
    return name[:100] # Limit to 100 chars

def get_target_results_dir(base_output_dir, target):
    """Creates and returns the path to the results directory for a specific target."""
    target_identifier = sanitize_filename(target)
    target_dir = os.path.join(base_output_dir, target_identifier)
    os.makedirs(target_dir, exist_ok=True)
    return target_dir

def get_phase_results_dir(target_results_dir, phase_name):
    """Creates and returns the path to a specific phase (recon, scans, analysis) directory."""
    phase_dir = os.path.join(target_results_dir, phase_name)
    os.makedirs(phase_dir, exist_ok=True)
    return phase_dir

if __name__ == '__main__':
    # Example Usage
    base_dir = "../results_test" # Test relative to utils dir
    test_targets = ["example.com", "https://test.example.org/path?query=1", "192.168.1.1"]

    for target in test_targets:
        print(f"Original Target: {target}")
        sanitized = sanitize_filename(target)
        print(f"Sanitized Name: {sanitized}")

        target_res_dir = get_target_results_dir(base_dir, target)
        print(f"Target Results Dir: {target_res_dir}")

        recon_dir = get_phase_results_dir(target_res_dir, "recon")
        print(f"Recon Dir: {recon_dir}")

        scan_dir = get_phase_results_dir(target_res_dir, "scans")
        print(f"Scan Dir: {scan_dir}")

        analysis_dir = get_phase_results_dir(target_res_dir, "analysis")
        print(f"Analysis Dir: {analysis_dir}")
        print("-" * 20)

    # Clean up test directory
    # import shutil
    # if os.path.exists(base_dir):
    #     shutil.rmtree(base_dir)
