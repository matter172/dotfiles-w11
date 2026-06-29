#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Downloads and installs WinGet (App Installer) on Windows IoT Enterprise LTSC.

.DESCRIPTION
    Fetches the latest WinGet release assets from this repository's GitHub Releases,
    downloads them to a temporary folder, installs all dependencies, and then
    installs WinGet itself.

.PARAMETER Repo
    The GitHub repository in "owner/repo" format.
    Default: change this to your own repo.

.PARAMETER Architecture
    Target architecture: x64 or arm64.
    Default: auto-detected from the current machine.

.EXAMPLE
    .\Install-WinGet.ps1

.EXAMPLE
    .\Install-WinGet.ps1 -Repo "myorg/myrepo" -Architecture arm64
#>

param (
    [string]$Repo = "YOUR_ORG/YOUR_REPO",   # <-- change this
    [ValidateSet("x64", "arm64")]
    [string]$Architecture = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Success([string]$Message) {
    Write-Host "    OK: $Message" -ForegroundColor Green
}

function Write-Fail([string]$Message) {
    Write-Host "    FAIL: $Message" -ForegroundColor Red
}

function Install-Appx([string]$Label, [string]$Path) {
    Write-Step "Installing $Label"
    try {
        Add-AppxPackage -Path $Path
        Write-Success "$Label installed."
    } catch {
        Write-Fail "Add-AppxPackage failed for $Label`: $_"
        throw
    }
}

# ---------------------------------------------------------------------------
# Detect architecture
# ---------------------------------------------------------------------------

if (-not $Architecture) {
    $arch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
    $Architecture = if ($arch -match "ARM") { "arm64" } else { "x64" }
}

Write-Host "`nWinGet Installer for Windows IoT Enterprise LTSC" -ForegroundColor Yellow
Write-Host "Repository : $Repo"
Write-Host "Architecture: $Architecture"

# ---------------------------------------------------------------------------
# Resolve latest release from GitHub
# ---------------------------------------------------------------------------

Write-Step "Fetching latest release from $Repo"

$apiUrl  = "https://api.github.com/repos/$Repo/releases/latest"
$headers = @{ "User-Agent" = "WinGet-IoT-Installer" }

try {
    $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
} catch {
    throw "Could not reach GitHub API. Check your internet connection and repo name.`n$_"
}

$tag    = $release.tag_name
$assets = $release.assets

Write-Success "Found release: $tag"

# ---------------------------------------------------------------------------
# Map asset names -> download URLs
# ---------------------------------------------------------------------------

function Get-AssetUrl([string]$Pattern) {
    $asset = $assets | Where-Object { $_.name -like $Pattern } | Select-Object -First 1
    if (-not $asset) { throw "Asset matching '$Pattern' not found in release $tag." }
    return $asset.browser_download_url
}

$urls = @{
    msixbundle = Get-AssetUrl "*.msixbundle"
    license    = Get-AssetUrl "License1.xml"
    vclibs     = Get-AssetUrl "Microsoft.VCLibs.$Architecture.14.00.Desktop.appx"
    uixaml     = Get-AssetUrl "Microsoft.UI.Xaml.2.8.$Architecture.appx"
}

# ---------------------------------------------------------------------------
# Create temp directory
# ---------------------------------------------------------------------------

$tempDir = Join-Path $env:TEMP "WinGetInstall_$tag"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Step "Downloading assets to: $tempDir"

function Download-Asset([string]$Label, [string]$Url) {
    $fileName = Split-Path $Url -Leaf
    $outPath  = Join-Path $tempDir $fileName
    Write-Host "    $Label -> $fileName"
    Invoke-WebRequest -Uri $Url -OutFile $outPath -UseBasicParsing
    return $outPath
}

$msixPath    = Download-Asset "WinGet bundle"        $urls.msixbundle
$licensePath = Download-Asset "License XML"          $urls.license
$vclibsPath  = Download-Asset "VCLibs ($Architecture)" $urls.vclibs
$uixamlPath  = Download-Asset "UI.Xaml ($Architecture)" $urls.uixaml

Write-Success "All files downloaded."

# ---------------------------------------------------------------------------
# Install dependencies then WinGet
# ---------------------------------------------------------------------------

Install-Appx "VCLibs ($Architecture)" $vclibsPath
Install-Appx "Microsoft.UI.Xaml 2.8 ($Architecture)" $uixamlPath
Install-Appx "WinGet (msixbundle)" $msixPath

Write-Step "Provisioning WinGet with license (Add-AppxProvisionedPackage)"
try {
    Add-AppxProvisionedPackage `
        -Online `
        -PackagePath $msixPath `
        -LicensePath $licensePath | Out-Null
    Write-Success "WinGet provisioned successfully."
} catch {
    Write-Fail "Provisioning failed: $_"
    throw
}

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------

Write-Step "Verifying WinGet installation"

$wingetExe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"

if (Test-Path $wingetExe) {
    Write-Success "winget.exe found at: $wingetExe"
} else {
    Write-Host "    winget.exe not yet visible at expected path." -ForegroundColor Yellow
    Write-Host "    Try restarting PowerShell or your machine if the command is not recognised." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

Write-Step "Cleaning up temp folder"
Remove-Item $tempDir -Recurse -Force
Write-Success "Temp folder removed."

Write-Host "`nDone! Run 'winget --version' to confirm." -ForegroundColor Green