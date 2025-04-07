#!/bin/bash

# --- Setup Script for Bug Bounty Automator (Bash Version) ---
echo "Starting Bug Bounty Automator Setup..."

# --- Check Prerequisites ---
echo "Checking prerequisites..."

# 1. Check Python 3 and Pip
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] Python 3 is not found. Please install Python 3."
    exit 1
else
    echo "[OK] Python 3 found."
fi

if ! command -v pip3 &> /dev/null; then
    echo "[ERROR] pip3 is not found. Please ensure Python 3 is properly installed."
    exit 1
else
    echo "[OK] pip3 found."
fi

# --- Install Python Dependencies ---
echo "Installing Python dependencies from requirements.txt..."
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo "[WARN] pip3 install command failed. Please check pip logs."
    else
        echo "[OK] Python dependencies installed."
    fi
else
    echo "[WARN] requirements.txt not found. Skipping Python dependency installation."
fi

# --- Check and Install Go Tools ---
echo "Checking for Go compiler..."
if command -v go &> /dev/null; then
    echo "[OK] Go compiler found."
    echo "Installing Go-based tools (subfinder, httpx, naabu, nuclei)..."
    GO_TOOLS=(
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
        "github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
    )
    for TOOL in "${GO_TOOLS[@]}"; do
        echo "Installing $TOOL ..."
        go install -v "$TOOL"
        if [ $? -ne 0 ]; then
            echo "[WARN] Failed to install $TOOL. Check Go environment."
        fi
    done
else
    echo "[WARN] Go compiler not found. Skipping Go tool installations."
    echo "Install Go and ensure GOPATH/bin is in PATH, then run:"
    echo "  go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    echo "  go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
    echo "  go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    echo "  go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
fi

# --- Check and Install Nmap ---
echo "Checking for Nmap..."
if command -v nmap &> /dev/null; then
    echo "[OK] Nmap found."
else
    echo "[INFO] Nmap not found. You may need to install it manually."
    echo "On Debian/Ubuntu: sudo apt-get install nmap"
    echo "On macOS (with Homebrew): brew install nmap"
fi

# --- Check and Install Nikto Dependencies and Clone Nikto ---
echo "Checking for Nikto dependencies (Git, Perl)..."
if ! command -v git &> /dev/null; then
    echo "[WARN] Git not found. Cannot clone Nikto."
    echo "Install Git and try again."
fi

if ! command -v perl &> /dev/null; then
    echo "[WARN] Perl not found. Nikto requires Perl."
    echo "Install Perl and try again."
fi

NIKTO_DIR="./tools/nikto"
if [ -d "$NIKTO_DIR" ]; then
    echo "[INFO] Nikto directory exists. Skipping clone."
else
    if command -v git &> /dev/null && command -v perl &> /dev/null; then
        echo "Cloning Nikto repository..."
        mkdir -p "./tools"
        git clone https://github.com/sullo/nikto.git "$NIKTO_DIR"
        if [ $? -ne 0 ]; then
            echo "[WARN] Failed to clone Nikto. Check Git and network."
        else
            echo "[OK] Nikto cloned to $NIKTO_DIR."
        fi
    fi
fi

# --- Final Verification ---
echo "Performing basic tool verification..."
TOOLS=(python3 pip3 go subfinder httpx naabu nuclei nmap git perl)
for TOOL in "${TOOLS[@]}"; do
    if command -v "$TOOL" &> /dev/null; then
        echo "[OK] $TOOL found."
    else
        echo "[WARN] $TOOL not found."
    fi
done

echo "Setup script finished. Review any WARN messages above."
