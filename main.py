import yaml
import os
import subprocess
import logging
import argparse
from utils import file_handler, llm_analyzer # Assuming utils is importable

# --- Configuration ---
CONFIG_FILE = "config/config.yaml"
DEFAULT_TARGETS_FILE = "targets/targets.txt"

# --- Logging Setup ---
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    handlers=[logging.StreamHandler()]) # Output logs to console

def load_config(config_path):
    """Loads YAML configuration file."""
    try:
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
        logging.info(f"Configuration loaded from {config_path}")
        return config
    except FileNotFoundError:
        logging.error(f"Configuration file not found: {config_path}")
        return None
    except yaml.YAMLError as e:
        logging.error(f"Error parsing configuration file {config_path}: {e}")
        return None

def read_targets(targets_file):
    """Reads targets from a file, skipping empty lines and comments."""
    targets = []
    try:
        with open(targets_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    targets.append(line)
        logging.info(f"Read {len(targets)} targets from {targets_file}")
        return targets
    except FileNotFoundError:
        logging.error(f"Targets file not found: {targets_file}")
        return []

def run_script(script_path, target, target_results_dir, phase_name):
    """Runs an external script (e.g., bash) for a specific phase."""
    if not os.path.exists(script_path):
        logging.error(f"{phase_name.capitalize()} script not found: {script_path}")
        return False

    # Make script executable (important for Linux/macOS, might not be needed/work on Windows cmd.exe)
    try:
        os.chmod(script_path, 0o755)
    except OSError as e:
        logging.warning(f"Could not set executable permission on {script_path}: {e}")

    logging.info(f"Running {phase_name} script for target: {target}")
    try:
        # Pass target and results directory as arguments or environment variables
        # Using environment variables might be cleaner for complex paths
        env = os.environ.copy()
        env['TARGET'] = target
        env['RESULTS_DIR'] = target_results_dir
        env['PHASE_NAME'] = phase_name # e.g., 'recon', 'scan'

        # Determine interpreter based on script extension (simple approach)
        interpreter = []
        if script_path.endswith(".sh"):
            interpreter = ["bash"] # Or potentially ["sh"] or handle Windows git-bash/WSL
        elif script_path.endswith(".py"):
            interpreter = ["python"]
        # Add other interpreters as needed

        command = interpreter + [script_path]

        # Using shell=True can be a security risk if script_path is user-controlled,
        # but might be necessary depending on how scripts are written.
        # Prefer passing args directly if possible. Here, we use env vars.
        process = subprocess.run(command, capture_output=True, text=True, env=env, check=False) # check=False to handle errors manually

        if process.returncode == 0:
            logging.info(f"{phase_name.capitalize()} script completed successfully for {target}.")
            logging.debug(f"Script output:\n{process.stdout}")
            return True
        else:
            logging.error(f"{phase_name.capitalize()} script failed for {target} with return code {process.returncode}.")
            logging.error(f"Script stderr:\n{process.stderr}")
            logging.error(f"Script stdout:\n{process.stdout}")
            return False

    except Exception as e:
        logging.error(f"Error running {phase_name} script {script_path} for {target}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Automated Bug Bounty Framework")
    parser.add_argument("-t", "--targets", default=DEFAULT_TARGETS_FILE,
                        help=f"Path to the targets file (default: {DEFAULT_TARGETS_FILE})")
    parser.add_argument("-c", "--config", default=CONFIG_FILE,
                        help=f"Path to the configuration file (default: {CONFIG_FILE})")
    args = parser.parse_args()

    config = load_config(args.config)
    if not config:
        return # Exit if config fails to load

    targets = read_targets(args.targets)
    if not targets:
        return # Exit if no targets

    base_output_dir = config.get('output', {}).get('base_directory', 'results')
    os.makedirs(base_output_dir, exist_ok=True) # Ensure base output dir exists

    # --- Workflow Execution ---
    for target in targets:
        logging.info(f"--- Processing Target: {target} ---")
        target_results_dir = file_handler.get_target_results_dir(base_output_dir, target)

        # 1. Run Reconnaissance
        # TODO: Make script path configurable
        recon_script_path = "scripts/run_recon.sh"
        recon_success = run_script(recon_script_path, target, target_results_dir, "recon")

        if not recon_success:
            logging.warning(f"Reconnaissance failed for {target}. Skipping further analysis and scans.")
            continue # Move to the next target

        # 2. Run LLM Analysis (Optional)
        llm_config = config.get('llm', {})
        if llm_config.get('enabled', False):
            logging.info("LLM analysis enabled in config.")
            recon_dir = file_handler.get_phase_results_dir(target_results_dir, "recon")
            analysis_dir = file_handler.get_phase_results_dir(target_results_dir, "analysis")
            suggestions_file = os.path.join(analysis_dir, "llm_suggestions.txt")

            suggestions = llm_analyzer.get_llm_suggestions(
                target_name=file_handler.sanitize_filename(target), # Use sanitized name for consistency?
                recon_dir=recon_dir,
                model_name=llm_config.get('model', 'gpt-3.5-turbo'),
                prompt_template=llm_config.get('prompt_template', 'Default prompt needed') # Get from config
            )

            if suggestions:
                try:
                    with open(suggestions_file, "w", encoding="utf-8") as f:
                        f.write(suggestions)
                    logging.info(f"LLM suggestions saved to {suggestions_file}")
                except Exception as e:
                    logging.error(f"Failed to save LLM suggestions for {target}: {e}")
            else:
                logging.warning(f"Failed to generate LLM suggestions for {target}.")
        else:
            logging.info("LLM analysis disabled in config.")


        # 3. Run Scans (Example: Web Scan)
        # TODO: Add logic to determine which scans to run based on recon results
        # TODO: Make script paths configurable
        web_scan_script_path = "scripts/run_web_scan.sh"
        # Check if there are live web hosts found during recon before running web scan?
        # This requires parsing recon results, adding complexity. Start simple.
        scan_success = run_script(web_scan_script_path, target, target_results_dir, "scan")

        if not scan_success:
             logging.warning(f"Scanning failed for {target}.")
             # Decide if failure here should stop processing or just log

        logging.info(f"--- Finished Processing Target: {target} ---")

    logging.info("All targets processed.")

if __name__ == "__main__":
    main()
