# 🚀 Pull Request Merger (Windows)

Unified PowerShell toolkit to manage and merge GitHub pull requests safely from Windows.

## Features
- View all open PRs across your repos
- Safe bulk merge with safety checks (status checks, approvals, branch protection awareness)
- Close all PRs (with confirmations)
- Emergency force-merge with backup/rollback
- Logs and JSON results saved to `Logs/` and `Results/`

## Quick Start
```powershell
# Launch interactive menu (recommended)
.\n .\Pull-Request-Merger.ps1

# Or run direct operations
.
 .\Pull-Request-Merger.ps1 -Operation status
 .\Pull-Request-Merger.ps1 -Operation merge
 .\Pull-Request-Merger.ps1 -Operation close
 .\Pull-Request-Merger.ps1 -Operation force -Force
```

You’ll be prompted for a GitHub token if not supplied.

Required token scopes:
- repo
- workflow

## Direct Script Usage
You can also invoke the core tool directly:
```powershell
.
 .\GitHub-PR-Toolkit.ps1 -GitHubToken "<token>" -Operation menu
```

## Repository Structure
```
.
├─ GitHub-PR-Toolkit.ps1       # Unified core tool
├─ Pull-Request-Merger.ps1      # Windows wrapper (recommended)
├─ .github/workflows/ci.yml     # CI (lint/smoke)
├─ Logs/                        # Auto-created
├─ Results/                     # Auto-created
├─ .gitignore
├─ .gitattributes
├─ LICENSE
├─ CONTRIBUTING.md
└─ CODE_OF_CONDUCT.md
```

## Notes
- Always try Dry Run first via menu options before aggressive modes
- Keep your token secure and do not commit it

## License
MIT
