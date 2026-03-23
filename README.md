# PowerShell Profile

A modular PowerShell profile with custom functions, aliases, autocomplete enhancements, and utility scripts for a productive Windows development environment.

## Structure

```
PowerShell/
├── Microsoft.PowerShell_profile.ps1  # Main profile (loaded by PowerShell)
├── profile.ps1                        # Shared profile entry point
├── Microsoft.VSCode_profile.ps1       # VS Code terminal profile
├── Microsoft.PowerShellISE_profile.ps1
├── Modules/
│   ├── AliasDefinitions.psm1          # Aliases
│   ├── AutoComplete.psm1              # PSReadLine key bindings & completions
│   ├── Read-Files.psm1                # File reading utilities
│   ├── RemoveNodeModules.psm1         # Node.js cleanup utility
│   ├── Utils.psm1                     # General-purpose utilities
│   └── VariableDefinitions.psm1       # Global variable definitions
├── Scripts/
│   ├── Bootstrap.ps1                  # New machine setup script
│   ├── InstallProfile.ps1             # Install profile dependencies
│   ├── Cleanup-Node.ps1
│   ├── CloseTibia.ps1
│   ├── DetectKeypress.ps1
│   ├── DisableAcronis.ps1
│   ├── RemoveXboxGameBar.ps1
│   └── ToggleTaskbar.ps1
└── Help/
```

## Setup

### New Machine Bootstrap

Run as Administrator to set up a new Windows machine:

```powershell
.\Scripts\Bootstrap.ps1
```

Add `-AskBeforeExecuting` to confirm each step interactively:

```powershell
.\Scripts\Bootstrap.ps1 -AskBeforeExecuting
```

The bootstrap script handles:
- Setting PowerShell execution policy to Unrestricted
- Installing Chocolatey
- Installing Git and VS Code
- Installing and configuring OpenSSH (client + server)
- Installing Windows Terminal
- Running Windows10Debloater

### Install Profile Dependencies

```powershell
.\Scripts\InstallProfile.ps1
```

Installs required PowerShell modules: `Pscx`, `PSReadLine`, `PSEverything`, `PSFzf`, `Recycle`, `oh-my-posh`, and `LazyAdmin`.

## Modules

### Utils (`Utils.psm1`)

| Function | Description |
|---|---|
| `Edit-Profile` | Opens the profile directory in VS Code |
| `Reload-Profile` | Re-sources the current profile |
| `Relaunch-Admin` | Restarts PowerShell as Administrator |
| `New-File <path>` | Creates a file or updates its timestamp (like `touch`) |
| `New-Scratch [-Extension]` | Creates a numbered scratch file and opens it in IntelliJ IDEA |
| `New-Symbolic-Link <target> <link>` | Creates a symbolic link |
| `New-Hard-Link <target> <link>` | Creates a hard link |
| `Get-VsCodeExtension <name>` | Downloads a VS Code extension `.vsix` from the marketplace |
| `Get-RedirectedUrl <url>` | Resolves a URL redirect |
| `wget <url>` | Downloads a file by URL to the current directory |
| `export VAR=VALUE` | Sets an environment variable using bash-style syntax |
| `Update-NpmDependencies` | Updates all npm/yarn/bun dependencies to `@latest` |
| `CDBack` | Navigates to the parent directory |

### AutoComplete (`AutoComplete.psm1`)

Configures PSReadLine and key bindings for an improved terminal experience:

| Key | Action |
|---|---|
| `Up/Down Arrow` | History search (prefix-based) |
| `Right Arrow` | Accept next suggestion word |
| `End` | Accept full suggestion |
| `Ctrl+R` | Fuzzy reverse history search (fzf) |
| `Ctrl+T` | Fuzzy file finder (fzf) |
| `Ctrl+H` | Delete previous word |
| `F7` | Browse full history in a grid view |
| `F2` | Open help for the command under the cursor |

Also enables completions for `kubectl`, `aws-cli`, and `gh` (GitHub CLI) if installed.

### RemoveNodeModules (`RemoveNodeModules.psm1`)

Recursively finds and removes `node_modules` folders from the current directory tree.

```powershell
RemoveNodeModules              # Interactive removal
RemoveNodeModules -Dry         # Preview without deleting
RemoveNodeModules -Lockfiles   # Also remove lockfiles (package-lock.json, yarn.lock, etc.)
```

### Read-Files (`Read-Files.psm1`)

Token-aware file reading utilities, useful when piping file content to AI tools.

```powershell
Read-File <path> [-MaxTokens 5000] [-StartLine 1] [-EndLine 0]
Read-Files <path1> <path2> ...  # Also aliased as `catx` and `view`
```

### AliasDefinitions (`AliasDefinitions.psm1`)

| Alias | Command |
|---|---|
| `ep` | `Edit-Profile` |
| `rpp` | `Reload-Profile` |
| `sudo` / `psadmin` | `Relaunch-Admin` |
| `touch` | `New-File` |
| `scratch` | `New-Scratch` |
| `ln` | `New-Symbolic-Link` |
| `lh` | `New-Hard-Link` |
| `..` | Go up one directory |
| `k` | `kubectl` |
| `paste` | `Get-Clipboard` |
| `cde` | Fuzzy `cd` using Everything search |

## Profile Variables

| Variable | Value |
|---|---|
| `$doc` | `~\Documents` |
| `$psdir` | `~\Documents\WindowsPowerShell` |
| `$Scripts` | Object with properties for each script path in `Scripts/` |
| `$history` | Path to PSReadLine history file |

## Profile Functions (main profile)

Additional functions defined directly in `Microsoft.PowerShell_profile.ps1`:

| Function | Description |
|---|---|
| `hh <term>` | Fuzzy search full command history |
| `Show-Notification` | Display a Windows toast notification |
| `Copy-Fast <src> <dst>` | Fast file copy using `robocopy` with multi-threading |
| `Set-PathVariable` | Add or remove entries from `$env:Path` |
| `Set-DropboxIgnored` | Mark/unmark files or folders as Dropbox sync-ignored |
| `Join-ffmpegMp4` | Concatenate multiple MP4 files using ffmpeg |
| `Stop-Process-Gracefully` | Close a process by name gracefully before force-stopping |
| `Get-Tree / Remove-Tree` | Recursively list or delete a directory tree |
| `Scrub` | Filter pipeline strings: removes blank lines and trims whitespace |
| `Get-EnumValues` | List all values of a .NET enum type |

## Dependencies

- [oh-my-posh](https://ohmyposh.dev/) — prompt theme engine
- [PSReadLine](https://github.com/PowerShell/PSReadLine) — improved line editing
- [PSFzf](https://github.com/kelleyma49/PSFzf) — fzf integration (`Ctrl+R`, `Ctrl+T`)
- [PSEverything](https://github.com/guibranco/PSEverything) — Everything search integration
- [Pscx](https://github.com/Pscx/Pscx) — PowerShell Community Extensions
- [Recycle](https://www.powershellgallery.com/packages/Recycle) — recycle bin support
- [Chocolatey](https://chocolatey.org/) — Windows package manager
- [fzf](https://github.com/junegunn/fzf) — fuzzy finder CLI
