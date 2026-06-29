<#
.SYNOPSIS
    Installs apps via WinGet silently.
.DESCRIPTION
    Runs after Install-WinGet.ps1. Installs a curated list of apps
    using WinGet with no prompts.
    NOTE: Run as a normal user, NOT as Administrator.
          winget installs apps into your user profile — running elevated
          would install them under the Administrator account instead.
.EXAMPLE
    .\Install-WinGet-Apps.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Success([string]$Message) {
    Write-Host "    OK: $Message" -ForegroundColor Green
}

function Write-Fail([string]$Message) {
    Write-Host "    FAIL: $Message" -ForegroundColor Red
}

# ---------------------------------------------------------------------------
# Verify winget is available
# ---------------------------------------------------------------------------

Write-Step "Checking WinGet"

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
    # Fallback: locate winget.exe directly in WindowsApps
    $wingetExe = Get-Item "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe" -ErrorAction SilentlyContinue
    if (-not $wingetExe) {
        throw "winget not found. Run Install-WinGet.ps1 first, then restart PowerShell."
    }
    $env:PATH += ";$($wingetExe.DirectoryName)"
}

Write-Success "WinGet found: $(winget --version)"

# ---------------------------------------------------------------------------
# App list
# ---------------------------------------------------------------------------

$apps = @(
    @{ id = "Valve.Steam";                  name = "Steam"                   }
    @{ id = "EpicGames.EpicGamesLauncher";  name = "Epic Games Launcher"     }
    @{ id = "Discord.Discord";              name = "Discord"                 }
    @{ id = "Brave.Brave";                  name = "Brave Browser"           }
    @{ id = "TechPowerUp.NVCleanstall";     name = "NVCleanstall"            }
    @{ id = "RiotGames.Valorant.AP";        name = "Valorant (Asia-Pacific)" }
    @{ id = "Microsoft.PowerToys";          name = "PowerToys"               }
)

# ---------------------------------------------------------------------------
# Install each app
# ---------------------------------------------------------------------------

$failed = @()

foreach ($app in $apps) {
    Write-Step "Installing $($app.name)"
    try {
        winget install --exact --id $app.id `
            --accept-package-agreements `
            --accept-source-agreements `
            --silent
        Write-Success "$($app.name) installed."
    } catch {
        if ($_.Exception.Message -match "0x8A150101" -or $_ -match "already installed") {
            Write-Host "    SKIP: $($app.name) is already installed." -ForegroundColor Yellow
        } else {
            Write-Fail "$($app.name) failed: $_"
            $failed += $app.name
        }
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host "`n--- Summary ---" -ForegroundColor White

if ($failed.Count -eq 0) {
    Write-Success "All apps installed successfully."
} else {
    Write-Host "    The following apps failed to install:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "      - $_" -ForegroundColor Red }
}