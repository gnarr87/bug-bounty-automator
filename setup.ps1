# PowerShell Setup Script for Bug Bounty Automator

Write-Host "Starting Bug Bounty Automator Setup..." -ForegroundColor Yellow

# --- Helper Function to Check Command Existence ---
function Test-CommandExists {
    param(
        [string]$commandName
    )
    return (Get-Command $commandName -ErrorAction SilentlyContinue) -ne $null
}

# --- Check Prerequisites ---
Write-Host "`n[INFO] Checking prerequisites..."

# 1. Check Python 3 and Pip
$pythonExists = Test-CommandExists python
$pipExists = Test-CommandExists pip

if (-not $pythonExists) {
    Write-Host "[ERROR] Python 3 is not found in PATH. Please install Python 3 and ensure it's added to your PATH." -ForegroundColor Red
    Write-Host "Download from: https://www.python.org/downloads/"
    # Consider adding a check for python3 alias as well
    exit 1
} else {
    Write-Host "[OK] Python found."
}

if (-not $pipExists) {
    Write-Host "[ERROR] pip is not found in PATH. Please ensure Python's Scripts directory is in your PATH or reinstall Python." -ForegroundColor Red
    exit 1
} else {
    Write-Host "[OK] pip found."
}

# --- Install Python Dependencies ---
Write-Host "`n[INFO] Installing Python dependencies from requirements.txt..."
$requirementsFile = ".\requirements.txt"
if (Test-Path $requirementsFile) {
    pip install -r $requirementsFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] pip install command failed with exit code $LASTEXITCODE. Please check pip logs." -ForegroundColor Yellow
        # Don't exit, maybe some packages installed
    } else {
        Write-Host "[OK] Python dependencies installed (or already satisfied)."
    }
} else {
    Write-Host "[WARN] requirements.txt not found. Skipping Python dependency installation." -ForegroundColor Yellow
}

# --- Check and Install Go Tools ---
Write-Host "`n[INFO] Checking for Go compiler..."
$goExists = Test-CommandExists go
if ($goExists) {
    Write-Host "[OK] Go compiler found."
    Write-Host "[INFO] Attempting to install Go-based tools (subfinder, httpx, naabu, nuclei)..."
    $goTools = @(
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest",
        "github.com/projectdiscovery/httpx/cmd/httpx@latest",
        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest",
        "github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
    )
    foreach ($tool in $goTools) {
        Write-Host "Installing $tool ..."
        go install -v $tool
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARN] Failed to install $tool using 'go install'. Check Go environment setup (GOPATH, GOBIN in PATH)." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "[WARN] Go compiler not found in PATH. Cannot automatically install Go-based tools (subfinder, httpx, naabu, nuclei)." -ForegroundColor Yellow
    Write-Host "Please install Go (https://go.dev/doc/install) and ensure GOPATH/bin is in your PATH, then run:"
    Write-Host "  go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    Write-Host "  go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
    Write-Host "  go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    Write-Host "  go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
}

# --- Check and Install Nmap ---
Write-Host "`n[INFO] Checking for Nmap..."
$nmapExists = Test-CommandExists nmap
if ($nmapExists) {
    Write-Host "[OK] Nmap found."
} else {
    Write-Host "[INFO] Nmap not found. Attempting installation using winget..."
    $wingetExists = Test-CommandExists winget
    if ($wingetExists) {
        winget install --id Nmap.Nmap -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARN] winget install for Nmap failed. Please install Nmap manually." -ForegroundColor Yellow
            Write-Host "Download from: https://nmap.org/download.html"
        } else {
             Write-Host "[OK] Nmap installation via winget attempted. Please verify it's now in PATH."
        }
    } else {
        Write-Host "[WARN] winget command not found. Cannot automatically install Nmap." -ForegroundColor Yellow
        Write-Host "Please install Nmap manually from: https://nmap.org/download.html"
    }
}

# --- Check and Install Nikto Dependencies (Git, Perl) and Clone Nikto ---
Write-Host "`n[INFO] Checking for Nikto dependencies (Git, Perl)..."
$gitExists = Test-CommandExists git
$perlExists = Test-CommandExists perl

if (-not $gitExists) {
    Write-Host "[WARN] Git not found in PATH. Cannot clone Nikto repository." -ForegroundColor Yellow
    Write-Host "Please install Git (https://git-scm.com/download/win) and ensure it's in PATH."
}
if (-not $perlExists) {
    Write-Host "[WARN] Perl not found in PATH. Nikto requires Perl to run." -ForegroundColor Yellow
    Write-Host "Please install Perl (e.g., Strawberry Perl: https://strawberryperl.com/) and ensure it's in PATH."
}

$niktoDir = ".\tools\nikto" # Define a local directory for tools
if ($gitExists -and $perlExists) {
    Write-Host "[INFO] Attempting to clone Nikto repository..."
    if (-not (Test-Path $niktoDir)) {
        New-Item -ItemType Directory -Force -Path ".\tools" | Out-Null
        git clone https://github.com/sullo/nikto.git $niktoDir
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARN] Failed to clone Nikto repository. Check Git setup and network connection." -ForegroundColor Yellow
        } else {
            Write-Host "[OK] Nikto repository cloned to $niktoDir."
            Write-Host "[INFO] You may need to adjust the NIKTO path in scripts/run_web_scan.sh or add $niktoDir\program to your PATH."
        }
    } else {
        Write-Host "[INFO] Nikto directory already exists at $niktoDir. Skipping clone."
    }
} else {
     Write-Host "[INFO] Skipping Nikto clone due to missing Git or Perl."
}


# --- IMPORTANT: Bash Environment Warning ---
Write-Host "`n" + ("-"*60) -ForegroundColor Cyan
Write-Host "IMPORTANT NOTE: Running the Automation Scripts" -ForegroundColor Cyan
Write-Host ("-"*60) -ForegroundColor Cyan
Write-Host "The core automation logic in 'main.py' currently relies on executing"
Write-Host "'scripts/run_recon.sh' and 'scripts/run_web_scan.sh'."
Write-Host "These are BASH scripts (.sh) and require a Bash-compatible environment"
Write-Host "to run correctly on Windows."
Write-Host ""
Write-Host "You MUST have one of the following installed and configured:" -ForegroundColor Yellow
Write-Host "  1. Git Bash (comes with Git for Windows: https://git-scm.com/download/win)"
Write-Host "  2. Windows Subsystem for Linux (WSL) with a Linux distribution installed."
Write-Host ""
Write-Host "Ensure that the 'bash' command from one of these environments is accessible"
Write-Host "in the terminal where you run 'python main.py'."
Write-Host "Alternatively, you could modify 'main.py' and rewrite the '.sh' scripts"
Write-Host "in Python or PowerShell."
Write-Host ("-"*60) -ForegroundColor Cyan


# --- Final Verification (Basic) ---
Write-Host "`n[INFO] Performing basic tool verification (checking if commands are found)..."
$toolsToCheck = @("python", "pip", "go", "subfinder", "httpx", "naabu", "nuclei", "nmap", "git", "perl")
foreach ($tool in $toolsToCheck) {
    if (Test-CommandExists $tool) {
        Write-Host "[OK] Found: $tool" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Not Found: $tool (May require manual installation/PATH adjustment)" -ForegroundColor Yellow
    }
}
# Note: Nikto isn't directly executable, needs perl nikto.pl

Write-Host "`nSetup script finished." -ForegroundColor Yellow
Write-Host "Please review any WARN or ERROR messages above and complete manual steps if needed."
Write-Host "Remember the requirement for Git Bash or WSL to run the .sh scripts!"
