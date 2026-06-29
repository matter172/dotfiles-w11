# dotfiles-w11

WinGet installer for **Windows IoT Enterprise LTSC** — editions that ship without the Microsoft Store and therefore can't install WinGet the normal way.

A GitHub Actions workflow automatically tracks the latest WinGet release, bundles all required dependencies, and publishes them as a single GitHub Release. A PowerShell script then downloads and installs everything in one shot.

---

## Quick install

Open **PowerShell as Administrator** and run:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/matter172/dotfiles-w11/main/Install-WinGet.ps1)))
```

That's it. The script will:
1. Detect your architecture (x64 or arm64) automatically
2. Fetch the latest release assets from this repo
3. Download them to a temp folder
4. Install VCLibs → UI.Xaml → WinGet in the correct order
5. Provision WinGet with the license file
6. Clean up the temp folder

---

## What gets installed

| File | Purpose |
|---|---|
| `Microsoft.DesktopAppInstaller.msixbundle` | WinGet itself |
| `License1.xml` | Required license for provisioning |
| `Microsoft.VCLibs.*.14.00.Desktop.appx` | VC++ runtime dependency |
| `Microsoft.UI.Xaml.2.8.*.appx` | UI framework dependency |

---

## How the automation works

`.github/workflows/update-winget-release.yml` runs every **Monday at 06:00 UTC** (or manually via Actions → Run workflow):

1. Fetches the latest release tag from [microsoft/winget-cli](https://github.com/microsoft/winget-cli/releases)
2. Skips if that tag already exists in this repo — no duplicate work
3. Downloads all 6 assets (msixbundle, license, VCLibs x64+arm64, UI.Xaml x64+arm64)
4. Deletes the previous release from this repo
5. Publishes a new release with all assets attached

---

## Requirements

- Windows 10/11 IoT Enterprise LTSC (or any Windows without the Store)
- PowerShell running as Administrator
- Internet access to reach GitHub

---

## Manual usage

```powershell
# Auto-detect architecture (default)
.\Install-WinGet.ps1

# Force a specific architecture
.\Install-WinGet.ps1 -Architecture arm64
```
