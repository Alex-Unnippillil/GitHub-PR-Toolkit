# 🚀 GitHub PR Management Toolkit

A comprehensive collection of PowerShell scripts for automated GitHub Pull Request management, conflict resolution, and repository maintenance.

## ⚠️ **IMPORTANT DISCLAIMER**

**These scripts are designed for advanced GitHub automation and should be used with extreme caution. They can:**
- Delete code and files
- Force merge pull requests
- Bypass branch protection rules
- Close pull requests without review
- Make irreversible changes to repositories

**Use at your own risk and only in controlled environments where you understand the consequences.**

## 📁 Repository Structure

```
├── 📂 Core Scripts/           # Main automation scripts
├── 📂 Conflict Resolution/     # Scripts for resolving merge conflicts
├── 📂 PR Management/          # Scripts for managing pull requests
├── 📂 Repository Tools/       # Repository maintenance and cleanup
├── 📂 Runner Scripts/         # Simplified execution scripts
├── 📂 Results/                # Output and log files
└── 📂 Examples/               # Usage examples and templates
```

## 🎯 **Core Scripts**

### 1. **Ultra Aggressive PR Merger** (`ultra-aggressive-pr-merger.ps1`)
**Use Case**: Nuclear option for merging ALL pull requests by any means necessary
- **What it does**: Removes ANY code causing conflicts, force merges, bypasses all protections
- **When to use**: Emergency situations, repository cleanup, when you need to merge everything regardless of conflicts
- **Risk Level**: ⚠️ EXTREME - Will delete code and force merge everything

### 2. **Aggressive Conflict Resolver** (`aggressive-conflict-resolver.ps1`)
**Use Case**: Resolves merge conflicts by aggressively removing problematic code
- **What it does**: Scans files for conflict patterns, removes conflicting lines, force merges
- **When to use**: When you have many PRs with conflicts and need to merge them quickly
- **Risk Level**: 🔴 HIGH - Will remove code to resolve conflicts

### 3. **Bypass Protection Merger** (`bypass-protection-merger.ps1`)
**Use Case**: Merges PRs while bypassing branch protection rules
- **What it does**: Uses admin privileges to override branch protection, force merges
- **When to use**: When branch protection is blocking necessary merges
- **Risk Level**: 🔴 HIGH - Bypasses security measures

## 🔧 **Conflict Resolution Scripts**

### 4. **Conflict Fixer** (`conflict-fixer.ps1`)
**Use Case**: Targeted conflict resolution for specific files
- **What it does**: Identifies and fixes merge conflicts in individual files
- **When to use**: When you need more control over what gets fixed
- **Risk Level**: 🟡 MEDIUM - More controlled than aggressive versions

### 5. **Auto Fix and Merge PRs** (`auto-fix-and-merge-prs.ps1`)
**Use Case**: Automated fixing and merging of problematic PRs
- **What it does**: Scans PRs for issues, fixes them, then merges
- **When to use**: Regular maintenance of open PRs
- **Risk Level**: 🟡 MEDIUM - Automated but controlled fixes

### 6. **Auto Fix and Merge PRs Clean** (`auto-fix-and-merge-prs-clean.ps1`)
**Use Case**: Cleaner version with better error handling
- **What it does**: Same as above but with improved error handling and logging
- **When to use**: Production environments where reliability is important
- **Risk Level**: 🟡 MEDIUM - More reliable version

## 📋 **PR Management Scripts**

### 7. **Auto Merge All** (`auto-merge-all.ps1`)
**Use Case**: Simple bulk merging of all open PRs
- **What it does**: Attempts to merge all PRs using multiple strategies
- **When to use**: When you want to merge everything that can be merged
- **Risk Level**: 🟡 MEDIUM - Standard merge attempts

### 8. **Auto Merge with Conflict Resolution** (`auto-merge-with-conflict-resolution.ps1`)
**Use Case**: Merges PRs with built-in conflict resolution
- **What it does**: Combines merging and conflict resolution in one script
- **When to use**: When you expect conflicts and want to handle them automatically
- **Risk Level**: 🟡 MEDIUM - Automated conflict handling

### 9. **Working PR Merger** (`working-pr-merger.ps1`)
**Use Case**: Reliable PR merging with error handling
- **What it does**: Merges PRs with comprehensive error handling and retry logic
- **When to use**: Production environments where reliability is critical
- **Risk Level**: 🟢 LOW - Built-in safety measures

## 🗂️ **Repository Tools**

### 10. **Force Merge All** (`force-merge-all.ps1`)
**Use Case**: Force merge all PRs regardless of status
- **What it does**: Uses force merge strategies to merge everything
- **When to use**: When standard merges are failing
- **Risk Level**: 🔴 HIGH - Force operations

### 11. **Force Merge Clean** (`force-merge-clean.ps1`)
**Use Case**: Clean force merging with better logging
- **What it does**: Force merges with improved error handling
- **When to use**: When you need force merges but want better tracking
- **Risk Level**: 🔴 HIGH - Force operations

### 12. **Force Push to Main** (`force-push-to-main.ps1`)
**Use Case**: Force push changes directly to main branch
- **What it does**: Bypasses PR process and pushes directly to main
- **When to use**: Emergency fixes, repository resets
- **Risk Level**: ⚠️ EXTREME - Direct main branch manipulation

### 13. **Git Force Merge** (`git-force-merge.ps1`)
**Use Case**: Low-level Git force merge operations
- **What it does**: Uses Git commands to force merge branches
- **When to use**: When you need direct Git control
- **Risk Level**: 🔴 HIGH - Direct Git manipulation

## 🔄 **PR Lifecycle Management**

### 14. **Close All PRs** (`close-all-prs.ps1`)
**Use Case**: Close all open pull requests
- **What it does**: Closes all PRs without merging
- **When to use**: Repository cleanup, starting fresh
- **Risk Level**: 🟡 MEDIUM - Closes work without saving

### 15. **Close Remaining PRs** (`close-remaining-prs.ps1`)
**Use Case**: Close PRs that couldn't be merged
- **What it does**: Closes PRs that failed other processing
- **When to use**: Cleanup after failed merge attempts
- **Risk Level**: 🟡 MEDIUM - Closes failed PRs

### 16. **Reopen All Closed PRs** (`reopen-all-closed-prs.ps1`)
**Use Case**: Reopen previously closed pull requests
- **What it does**: Reopens all closed PRs for reprocessing
- **When to use**: When you want to retry processing
- **Risk Level**: 🟢 LOW - Reopening is safe

### 17. **Reopen and Fix PRs** (`reopen-and-fix-prs.ps1`)
**Use Case**: Reopen PRs and attempt to fix them
- **What it does**: Combines reopening with fixing attempts
- **When to use**: When you want to give failed PRs another chance
- **Risk Level**: 🟡 MEDIUM - Reopening and fixing

### 18. **Reopen Fix PRs** (`reopen-fix-prs.ps1`)
**Use Case**: Reopen specific PRs for fixing
- **What it does**: Reopens PRs with targeted fixing
- **When to use**: Selective reprocessing
- **Risk Level**: 🟡 MEDIUM - Selective operations

### 19. **Simple Reopen PRs** (`simple-reopen-prs.ps1`)
**Use Case**: Basic PR reopening
- **What it does**: Simple script to reopen closed PRs
- **When to use**: When you just need to reopen PRs
- **Risk Level**: 🟢 LOW - Simple reopening

## 🚀 **Runner Scripts**

### 20. **Run Ultra Aggressive Merger** (`run-ultra-aggressive-merger.ps1`)
**Use Case**: Quick execution of ultra aggressive merging
- **What it does**: Simplified runner for the nuclear option
- **When to use**: When you need the most aggressive approach quickly
- **Risk Level**: ⚠️ EXTREME - Same as ultra aggressive merger

### 21. **Run Auto Fix** (`run-auto-fix.ps1`)
**Use Case**: Quick execution of auto fixing
- **What it does**: Simplified runner for auto fixing
- **When to use**: Regular maintenance runs
- **Risk Level**: 🟡 MEDIUM - Same as auto fix scripts

### 22. **Run Merge** (`run-merge.ps1`)
**Use Case**: Quick execution of merging
- **What it does**: Simplified runner for merging
- **When to use**: Standard merge operations
- **Risk Level**: 🟡 MEDIUM - Same as merge scripts

### 23. **Run Targeted Fix and Merge** (`run-targeted-fix-and-merge.ps1`)
**Use Case**: Quick execution of targeted fixing and merging
- **What it does**: Simplified runner for targeted operations
- **When to use**: When you need targeted processing
- **Risk Level**: 🟡 MEDIUM - Same as targeted scripts

## 🛠️ **Utility Scripts**

### 24. **Manual Merge** (`manual-merge.ps1`)
**Use Case**: Manual control over merge operations
- **What it does**: Provides manual control for merge operations
- **When to use**: When you need fine-grained control
- **Risk Level**: 🟡 MEDIUM - Manual control

### 25. **Merge All PRs** (`merge-all-prs.ps1`)
**Use Case**: Standard merging of all PRs
- **What it does**: Attempts to merge all PRs using standard methods
- **When to use**: Regular repository maintenance
- **Risk Level**: 🟢 LOW - Standard operations

### 26. **Nuclear PR Merger** (`nuclear-pr-merger.ps1`)
**Use Case**: Complete repository reset and merge
- **What it does**: Nuclear option for complete repository cleanup
- **When to use**: Complete repository reset scenarios
- **Risk Level**: ⚠️ EXTREME - Complete reset

## 📊 **Results and Logs**

- **Auto Merge Results**: JSON files containing merge operation results
- **Reopen Results**: JSON files containing reopen operation results
- **Log Files**: Various log files from script executions

## 🚀 **Quick Start**

### Prerequisites
1. **PowerShell 5.1+** or **PowerShell Core 6.0+**
2. **Git** installed and configured
3. **GitHub Personal Access Token** with appropriate permissions

### Basic Usage

```powershell
# Set your GitHub token
$env:GITHUB_TOKEN = "your_token_here"

# Run a simple merge operation
.\merge-all-prs.ps1 -GitHubToken $env:GITHUB_TOKEN

# Run with dry run first (recommended)
.\auto-fix-and-merge-prs.ps1 -GitHubToken $env:GITHUB_TOKEN -DryRun

# Run the nuclear option (use with extreme caution)
.\ultra-aggressive-pr-merger.ps1 -GitHubToken $env:GITHUB_TOKEN
```

### Advanced Usage

```powershell
# Custom local repository path
.\aggressive-conflict-resolver.ps1 -GitHubToken $env:GITHUB_TOKEN -LocalRepoPath ".\custom_path"

# Skip cleanup (keep local files for inspection)
.\auto-fix-and-merge-prs.ps1 -GitHubToken $env:GITHUB_TOKEN -SkipCleanup

# Dry run to see what would happen
.\ultra-aggressive-pr-merger.ps1 -GitHubToken $env:GITHUB_TOKEN -DryRun
```

## ⚠️ **Safety Recommendations**

1. **Always use `-DryRun` first** to see what changes would be made
2. **Test on non-production repositories** before using on important repos
3. **Backup your repositories** before running destructive scripts
4. **Use the least aggressive script** that will accomplish your goal
5. **Monitor script execution** and be ready to stop if needed
6. **Understand the consequences** of each script before running

## 🔒 **Required GitHub Permissions**

Your GitHub token needs these permissions:
- `repo` - Full control of private repositories
- `workflow` - Update GitHub Action workflows
- `admin:org` - Full organization access (if working with org repos)

## 📝 **Contributing**

1. **Fork the repository**
2. **Create a feature branch**
3. **Make your changes**
4. **Test thoroughly** (especially destructive operations)
5. **Submit a pull request**

## 📄 **License**

This project is provided as-is for educational and automation purposes. Use at your own risk.

## 🆘 **Support**

- **Issues**: Report bugs and feature requests
- **Discussions**: Ask questions and share experiences
- **Wiki**: Additional documentation and examples

## ⏰ **Last Updated**

Last updated: $(Get-Date -Format "yyyy-MM-dd")

---

**Remember: These scripts are powerful tools that can make irreversible changes. Always test first and use responsibly!**
