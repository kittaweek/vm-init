#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Info($msg) { Write-Host "  [+] $msg" -ForegroundColor Cyan }

# ── System update (works on both AMD64 and ARM64) ─────────────────────────────
Write-Host ""
Write-Host "── System update ──"
Info "Running winget upgrade --all..."
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
Info "All packages up to date."
