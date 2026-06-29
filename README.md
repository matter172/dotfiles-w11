# dotfiles-w11

WinGet installer for **Windows IoT Enterprise LTSC** — editions that ship without the Microsoft Store and therefore can't install WinGet the normal way.

A GitHub Actions workflow automatically tracks the latest WinGet release, bundles all required dependencies, and publishes them as a single GitHub Release. Two PowerShell scripts handle the rest: one installs WinGet itself, the other installs your apps.

---

## Step 1 — Install WinGet

Open **PowerShell as Administrator** and run:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/matter172/dotfiles-w11/main/Install-WinGet.ps1)))
```

**Then restart PowerShell** before continuing.

---

## Step 2 — Install Apps

Open a **normal PowerShell window (not as Administrator)** and run:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/matter172/dotfiles-w11/main/Install-WinGet-Apps.ps1)))
```

Apps installed:

| App | WinGet ID |
|---|---|
| Steam | `Valve.Steam` |
| Epic Games Launcher | `EpicGames.EpicGamesLauncher` |
| Discord | `Discord.Discord` |
| Brave Browser | `Brave.Brave` |
| NVCleanstall | `TechPowerUp.NVCleanstall` |

---

## What gets installed by Step 1

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
