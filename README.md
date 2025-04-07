# Bug Bounty Automator

## Overview

The Bug Bounty Automator is a framework designed to automate various tasks involved in bug bounty hunting. It integrates multiple security tools for reconnaissance, vulnerability scanning, and analysis, making it easier to identify potential vulnerabilities in target systems.

## Features

*   Modular design for easy extension and customization
*   Supports multiple target types (domains, IPs, URLs)
*   Integrates popular security tools for reconnaissance and scanning
*   Optional LLM (Large Language Model) analysis for prioritizing findings
*   Cross-platform setup scripts for Windows (PowerShell) and Linux/macOS (Bash)

## Prerequisites

Before using the Bug Bounty Automator, ensure you have the following installed:

*   Python 3.x
*   pip (Python package manager)
*   Go compiler (for installing Go-based tools)
*   Git
*   Perl (for Nikto)

## Setup

1.  Clone the repository:
    ```bash
    git clone https://github.com/gnarr87/bug-bounty-automator.git
    ```
2.  Navigate to the project directory:
    ```bash
    cd bug-bounty-automator
    ```
3.  Run the appropriate setup script for your environment:
    *   On Windows (in PowerShell as Administrator):
        ```powershell
        .\setup.ps1
        ```
    *   On Linux/macOS:
        ```bash
        ./setup.sh
        ```
4.  **Usage:**
    *   Edit `targets/targets.txt` to add your target domains, IPs, or URLs.
    *   Configure tool options and LLM settings in `config/config.yaml` as needed.
    *   Run the main script:
        ```bash
        python main.py
        ```

## Directory Structure

*   `main.py`: Main Python script orchestrating the workflow.
*   `config/`: Directory containing configuration files.
*   `targets/`: Directory for target lists.
*   `utils/`: Utility Python scripts.
*   `scripts/`: Directory for external tool execution scripts.
*   `results/`: Directory where scan results are stored (not committed by default).

## Contributing

Contributions are welcome. Please fork the repository, make your changes, and submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

*   ProjectDiscovery tools (`subfinder`, `httpx`, `naabu`, `nuclei`)
*   Nikto web server scanner
*   Other open-source security tools integrated
