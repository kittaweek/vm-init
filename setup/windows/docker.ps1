#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Info($msg) { Write-Host "  [+] $msg" -ForegroundColor Cyan }

# ── Docker Desktop (includes Compose plugin) ──────────────────────────────────
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Info "Installing Docker Desktop..."
    winget install --id Docker.DockerDesktop `
        --silent --accept-package-agreements --accept-source-agreements
} else {
    Info "Docker already installed, skipping."
}

# ── lazydocker ────────────────────────────────────────────────────────────────
if (-not (Get-Command lazydocker -ErrorAction SilentlyContinue)) {
    Info "Installing lazydocker..."
    winget install --id JesseDuffield.lazydocker `
        --silent --accept-package-agreements --accept-source-agreements
}

# ── ctop (not available on Windows — skip with notice) ────────────────────────
Write-Warning "ctop is not available natively on Windows. Use 'docker stats' or lazydocker instead."

# Reload PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path","User")

Info "Docker setup complete. Please restart to finalize Docker Desktop installation."
