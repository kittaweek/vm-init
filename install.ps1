#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── Detect Architecture ────────────────────────────────────────────────────────
$arch = $env:PROCESSOR_ARCHITECTURE   # AMD64, ARM64, x86
$isArm = $arch -eq "ARM64"

Write-Host "==> OS: windows | ARCH: $arch | ARM: $isArm"

# ── Run Windows package setup ──────────────────────────────────────────────────
Write-Host "==> Running Windows setup..."
& "$ScriptDir\setup\windows\packages.ps1"

# ── Docker (non-ARM only) ──────────────────────────────────────────────────────
if (-not $isArm) {
    Write-Host "==> Installing Docker (non-ARM)..."
    & "$ScriptDir\setup\windows\docker.ps1"
}

Write-Host ""
Write-Host "==> Setup complete! Please restart your terminal."
