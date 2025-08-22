# GitHub PR Toolkit Cleanup Script
# Organizes the scattered scripts into a backup directory for the new unified toolkit

param(
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,

    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

Write-Host "GitHub PR Toolkit Cleanup Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Define directories to organize
$directoriesToOrganize = @(
    "Core Scripts",
    "PR Management",
    "Conflict Resolution",
    "Repository Tools",
    "Runner Scripts"
)

# Define files to organize
$filesToOrganize = @(
    "auto-close-prs.ps1",
    "reopen-and-fix-prs.ps1",
    "reopen-fix-prs.ps1",
    "simple-reopen-prs.ps1",
    "run-auto-fix.ps1",
    "run-merge.ps1",
    "run-targeted-fix-and-merge.ps1",
    "run-ultra-aggressive-merger.ps1"
)

# Create backup directory
$backupDir = "Legacy-Scripts-Backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$newStructureDir = "Legacy-Scripts"

if (-not $DryRun) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    New-Item -ItemType Directory -Path $newStructureDir -Force | Out-Null
    Write-Host "Created backup directory: $backupDir" -ForegroundColor Green
    Write-Host "Created new structure directory: $newStructureDir" -ForegroundColor Green
} else {
    Write-Host "DRY RUN: Would create backup directory: $backupDir" -ForegroundColor Yellow
    Write-Host "DRY RUN: Would create new structure directory: $newStructureDir" -ForegroundColor Yellow
}

Write-Host ""

# Organize directories
Write-Host "Organizing directories..." -ForegroundColor Cyan
foreach ($dir in $directoriesToOrganize) {
    if (Test-Path $dir) {
        $sourcePath = $dir
        $destPath = Join-Path $newStructureDir $dir

        if (-not $DryRun) {
            if (Test-Path $destPath) {
                Remove-Item -Path $destPath -Recurse -Force
            }
            Move-Item -Path $sourcePath -Destination $destPath
            Write-Host "Moved: $dir -> $destPath" -ForegroundColor Green
        } else {
            Write-Host "DRY RUN: Would move: $dir -> $destPath" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Directory not found: $dir" -ForegroundColor Yellow
    }
}

Write-Host ""

# Organize individual files
Write-Host "Organizing individual files..." -ForegroundColor Cyan
foreach ($file in $filesToOrganize) {
    if (Test-Path $file) {
        $sourcePath = $file
        $destPath = Join-Path $newStructureDir $file

        if (-not $DryRun) {
            Move-Item -Path $sourcePath -Destination $destPath
            Write-Host "Moved: $file -> $destPath" -ForegroundColor Green
        } else {
            Write-Host "DRY RUN: Would move: $file -> $destPath" -ForegroundColor Yellow
        }
    } else {
        Write-Host "File not found: $file" -ForegroundColor Yellow
    }
}

Write-Host ""

# Create new README for the organized structure
$newReadmeContent = "# Legacy Scripts Archive

This directory contains the original scattered scripts that have been consolidated into the unified GitHub-PR-Toolkit.ps1.

## Directory Structure

* Core Scripts/ - High-level automation scripts
* PR Management/ - Pull request management scripts
* Conflict Resolution/ - Merge conflict resolution scripts
* Repository Tools/ - Repository maintenance scripts
* Runner Scripts/ - Execution wrapper scripts

## Migration

All functionality has been consolidated into:
* GitHub-PR-Toolkit.ps1 - Main unified tool
* Launch-Toolkit.ps1 - Simple launcher
* UNIFIED-TOOLKIT-README.md - Complete documentation

## Note

These scripts are kept for reference but are no longer maintained. Use the unified toolkit for all operations."

if (-not $DryRun) {
    $newReadmeContent | Out-File -FilePath (Join-Path $newStructureDir "README.md") -Encoding UTF8
    Write-Host "Created README for legacy scripts" -ForegroundColor Green
} else {
    Write-Host "DRY RUN: Would create README for legacy scripts" -ForegroundColor Yellow
}

Write-Host ""

# Create new workspace README
$workspaceReadmeContent = "# GitHub PR Management Toolkit - Unified Workspace

## What's New

This workspace has been reorganized to use the new Unified GitHub PR Toolkit that consolidates all functionality into a single, powerful tool.

## Current Structure

```
Workspace/
+ GitHub-PR-Toolkit.ps1          # Main unified tool (USE THIS!)
+ Launch-Toolkit.ps1             # Simple launcher
+ UNIFIED-TOOLKIT-README.md      # Complete documentation
+ Legacy-Scripts/                 # Original scattered scripts (archive)
+ Results/                        # Operation results (auto-created)
+ Logs/                           # Log files (auto-created)
+ temp_repo_checkout/             # Default repository path
```

## Quick Start

### Interactive Mode (Recommended)
```powershell
.\Launch-Toolkit.ps1
```

### Direct Operations
```powershell
# Check status
.\Launch-Toolkit.ps1 -Operation 'status'

# Merge all PRs
.\Launch-Toolkit.ps1 -Operation 'merge'

# Force merge (aggressive)
.\Launch-Toolkit.ps1 -Operation 'force' -Force
```

## Documentation

- UNIFIED-TOOLKIT-README.md - Complete usage guide
- Legacy-Scripts/ - Original scripts for reference

## Important

- Use the new unified toolkit for all operations
- Legacy scripts are archived and no longer maintained
- The unified tool includes all functionality plus improvements"

if (-not $DryRun) {
    $workspaceReadmeContent | Out-File -FilePath "README-UNIFIED.md" -Encoding UTF8
    Write-Host "Created new workspace README" -ForegroundColor Green
} else {
    Write-Host "DRY RUN: Would create README for legacy scripts" -ForegroundColor Yellow
}

Write-Host ""

# Summary
Write-Host "Cleanup Summary" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Host "This was a DRY RUN - no files were actually moved" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To actually perform the cleanup, run:" -ForegroundColor White
    Write-Host "  .\Cleanup-Old-Scripts.ps1" -ForegroundColor Cyan
} else {
    Write-Host "Cleanup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Files organized into: $newStructureDir" -ForegroundColor White
    Write-Host "New workspace README created: README-UNIFIED.md" -ForegroundColor White
    Write-Host ""
    Write-Host "You can now use the unified toolkit:" -ForegroundColor Green
    Write-Host "  .\Launch-Toolkit.ps1" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "For complete documentation, see: UNIFIED-TOOLKIT-README.md" -ForegroundColor Blue
