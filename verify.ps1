#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$pass  = 0
$fail  = 0
$skip  = 0

# ── Helpers ────────────────────────────────────────────────────────────────────
function Check-Command {
    param(
        [string]$Label,
        [string]$Cmd = ""
    )
    if ($Cmd -eq "") { $Cmd = $Label }
    if (Get-Command $Cmd -ErrorAction SilentlyContinue) {
        Write-Host "  [OK]   $Label" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "  [FAIL] $Label" -ForegroundColor Red
        $script:fail++
    }
}

function Skip-Item {
    param([string]$Label)
    Write-Host "  [SKIP] $Label" -ForegroundColor Yellow
    $script:skip++
}

function Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "── $Title ──" -ForegroundColor White
}

# ── Detect architecture ────────────────────────────────────────────────────────
# PROCESSOR_ARCHITECTURE: AMD64 | ARM64 | x86
$isArm = $env:PROCESSOR_ARCHITECTURE -eq "ARM64"
$archLabel = if ($isArm) { "ARM64" } else { "x86_64 (AMD64)" }

Write-Host "Platform: Windows / $archLabel" -ForegroundColor Cyan

# ── Common tools installed via winget ──────────────────────────────────────────
Section "Common tools"
Check-Command "fish"
Check-Command "starship"
Check-Command "zoxide"
Check-Command "atuin"
Check-Command "fzf"
Check-Command "btop"
Check-Command "duf"
Check-Command "ripgrep"   "rg"
Check-Command "fd"
Check-Command "bat"
Check-Command "eza"
Check-Command "delta"
Check-Command "jq"
Check-Command "fx"
Check-Command "glow"
Check-Command "yazi"
Check-Command "rclone"
Check-Command "tldr"
Check-Command "neovim"    "nvim"
Check-Command "vim"
Check-Command "tailscale"

# Note: htop, ncdu, mtr, tmux are Unix-only — not installed on Windows
Section "Unix-only tools (expected absent on Windows)"
foreach ($tool in @("htop", "ncdu", "mtr", "tmux")) {
    Skip-Item "$tool (Unix-only, not installed on Windows)"
}

# ── Docker (x86_64 / AMD64 only) ──────────────────────────────────────────────
Section "Docker (non-ARM)"
if (-not $isArm) {
    Check-Command "docker"

    # docker compose v2 plugin — invoked as 'docker compose'
    try {
        docker compose version 2>&1 | Out-Null
        Write-Host "  [OK]   docker compose plugin" -ForegroundColor Green
        $pass++
    } catch {
        Write-Host "  [FAIL] docker compose plugin" -ForegroundColor Red
        $fail++
    }

    Check-Command "lazydocker"

    # ctop is not available on Windows
    Skip-Item "ctop (not available on Windows — use 'docker stats' or lazydocker)"
} else {
    Skip-Item "Docker tools (ARM64 — not installed)"
}

# ── Summary ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "────────────────────────────────"
Write-Host "  Passed : $pass"  -ForegroundColor Green
if ($fail -gt 0) {
    Write-Host "  Failed : $fail"  -ForegroundColor Red
} else {
    Write-Host "  Failed : $fail"
}
if ($skip -gt 0) {
    Write-Host "  Skipped: $skip" -ForegroundColor Yellow
}
Write-Host "────────────────────────────────"
