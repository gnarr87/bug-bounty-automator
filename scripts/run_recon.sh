#!/bin/bash

# --- Reconnaissance Script ---
# This script performs initial recon steps for a given target.
# It expects TARGET and RESULTS_DIR environment variables to be set.

# --- Configuration ---
# Tools (assumed to be in PATH, enhance later to read from config)
SUBFINDER="subfinder"
ASSETFINDER="assetfinder" # Alternative/Additional subdomain tool
HTTPX="httpx"
NAABU="naabu"
NMAP="nmap"
WHATWEB="whatweb"

# Nmap options (consider making configurable)
NMAP_OPTIONS="-sV -T4 --open" # Scan for service versions, faster timing, only show open ports
NAABU_OPTIONS="-p -" # Scan all ports

# --- Input Validation ---
if [ -z "$TARGET" ]; then
  echo "[ERROR] TARGET environment variable is not set."
  exit 1
fi
if [ -z "$RESULTS_DIR" ]; then
  echo "[ERROR] RESULTS_DIR environment variable is not set."
  exit 1
fi

# --- Setup ---
# Sanitize target name for directory creation (optional, main.py already does this)
# TARGET_ID=$(echo "$TARGET" | sed -e 's|^https\?://||' -e 's/[\\/*?:"<>|]/_/g')
RECON_DIR="$RESULTS_DIR/recon"
mkdir -p "$RECON_DIR"

echo "-----------------------------------------------------"
echo "Starting Reconnaissance for Target: $TARGET"
echo "Results will be saved in: $RECON_DIR"
echo "-----------------------------------------------------"

# --- Tool Execution ---

# 1. Subdomain Enumeration (using subfinder)
echo "[INFO] Running Subdomain Enumeration (subfinder)..."
SUBDOMAINS_FILE="$RECON_DIR/subdomains_subfinder.txt"
if command -v $SUBFINDER &> /dev/null; then
  $SUBFINDER -d "$TARGET" -o "$SUBDOMAINS_FILE" -silent
  echo "[INFO] Subfinder finished. Results: $SUBDOMAINS_FILE"
else
  echo "[WARN] $SUBFINDER command not found. Skipping."
fi

# 1b. Subdomain Enumeration (using assetfinder - optional alternative)
# echo "[INFO] Running Subdomain Enumeration (assetfinder)..."
# ASSETFINDER_FILE="$RECON_DIR/subdomains_assetfinder.txt"
# if command -v $ASSETFINDER &> /dev/null; then
#   $ASSETFINDER --subs-only "$TARGET" | sort -u > "$ASSETFINDER_FILE"
#   echo "[INFO] Assetfinder finished. Results: $ASSETFINDER_FILE"
# else
#   echo "[WARN] $ASSETFINDER command not found. Skipping."
# fi

# Combine subdomain results (if using multiple tools)
# cat $RECON_DIR/subdomains_*.txt | sort -u > "$RECON_DIR/subdomains.txt"

# For simplicity, if only using subfinder:
if [ -f "$SUBDOMAINS_FILE" ]; then
  cp "$SUBDOMAINS_FILE" "$RECON_DIR/subdomains.txt"
fi


# 2. Live Host Discovery (using httpx on found subdomains)
echo "[INFO] Running Live Host Discovery (httpx)..."
LIVE_HOSTS_FILE="$RECON_DIR/live_hosts.txt"
SUBDOMAINS_INPUT_FILE="$RECON_DIR/subdomains.txt"
if command -v $HTTPX &> /dev/null && [ -f "$SUBDOMAINS_INPUT_FILE" ]; then
  cat "$SUBDOMAINS_INPUT_FILE" | $HTTPX -silent -o "$LIVE_HOSTS_FILE"
  echo "[INFO] httpx finished. Results: $LIVE_HOSTS_FILE"
elif ! command -v $HTTPX &> /dev/null; then
   echo "[WARN] $HTTPX command not found. Skipping."
elif [ ! -f "$SUBDOMAINS_INPUT_FILE" ]; then
   echo "[WARN] Subdomains file ($SUBDOMAINS_INPUT_FILE) not found. Skipping live host discovery."
fi

# 3. Port Scanning (using naabu on subdomains)
echo "[INFO] Running Fast Port Scanning (naabu)..."
PORTS_NAABU_FILE="$RECON_DIR/ports_naabu.txt"
if command -v $NAABU &> /dev/null && [ -f "$SUBDOMAINS_INPUT_FILE" ]; then
  $NAABU -list "$SUBDOMAINS_INPUT_FILE" $NAABU_OPTIONS -o "$PORTS_NAABU_FILE" -silent
  echo "[INFO] naabu finished. Results: $PORTS_NAABU_FILE"
elif ! command -v $NAABU &> /dev/null; then
  echo "[WARN] $NAABU command not found. Skipping."
elif [ ! -f "$SUBDOMAINS_INPUT_FILE" ]; then
   echo "[WARN] Subdomains file ($SUBDOMAINS_INPUT_FILE) not found. Skipping port scanning."
fi

# 4. Detailed Port Scanning & Service Version (using nmap on hosts from naabu)
echo "[INFO] Running Detailed Port Scanning & Service Version (nmap)..."
PORTS_TCP_FILE="$RECON_DIR/ports_tcp.txt"
NMAP_INPUT_FILE="$PORTS_NAABU_FILE" # Use hosts found by naabu
if command -v $NMAP &> /dev/null && [ -f "$NMAP_INPUT_FILE" ]; then
  # Extract unique hosts from naabu output
  HOSTS_FOR_NMAP=$(cut -d':' -f1 "$NMAP_INPUT_FILE" | sort -u)
  if [ -n "$HOSTS_FOR_NMAP" ]; then
    echo "$HOSTS_FOR_NMAP" > "$RECON_DIR/hosts_for_nmap.tmp"
    $NMAP $NMAP_OPTIONS -iL "$RECON_DIR/hosts_for_nmap.tmp" -oN "$PORTS_TCP_FILE"
    rm "$RECON_DIR/hosts_for_nmap.tmp"
    echo "[INFO] nmap finished. Results: $PORTS_TCP_FILE"
  else
    echo "[INFO] No hosts found by naabu to scan with nmap."
  fi
elif ! command -v $NMAP &> /dev/null; then
  echo "[WARN] $NMAP command not found. Skipping."
elif [ ! -f "$NMAP_INPUT_FILE" ]; then
   echo "[WARN] Naabu output file ($NMAP_INPUT_FILE) not found. Skipping nmap scan."
fi

# 5. Web Technology Identification (using httpx on live hosts)
echo "[INFO] Running Web Technology Identification (httpx -tech-detect)..."
WEB_TECH_FILE="$RECON_DIR/web_technologies.json"
if command -v $HTTPX &> /dev/null && [ -f "$LIVE_HOSTS_FILE" ]; then
  cat "$LIVE_HOSTS_FILE" | $HTTPX -silent -tech-detect -json -o "$WEB_TECH_FILE"
  echo "[INFO] httpx tech-detect finished. Results: $WEB_TECH_FILE"
elif ! command -v $HTTPX &> /dev/null; then
   echo "[WARN] $HTTPX command not found. Skipping tech detection."
elif [ ! -f "$LIVE_HOSTS_FILE" ]; then
   echo "[WARN] Live hosts file ($LIVE_HOSTS_FILE) not found. Skipping tech detection."
fi

# 5b. Alternative Web Technology Identification (using whatweb)
# echo "[INFO] Running Web Technology Identification (whatweb)..."
# WHATWEB_FILE="$RECON_DIR/web_technologies_whatweb.txt"
# if command -v $WHATWEB &> /dev/null && [ -f "$LIVE_HOSTS_FILE" ]; then
#   $WHATWEB --input-file="$LIVE_HOSTS_FILE" --log-brief="$WHATWEB_FILE" -q
#   echo "[INFO] whatweb finished. Results: $WHATWEB_FILE"
# elif ! command -v $WHATWEB &> /dev/null; then
#    echo "[WARN] $WHATWEB command not found. Skipping."
# elif [ ! -f "$LIVE_HOSTS_FILE" ]; then
#    echo "[WARN] Live hosts file ($LIVE_HOSTS_FILE) not found. Skipping whatweb."
# fi


echo "-----------------------------------------------------"
echo "Reconnaissance Phase Completed for Target: $TARGET"
echo "-----------------------------------------------------"

exit 0 # Indicate success
