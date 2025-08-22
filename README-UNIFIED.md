# GitHub PR Management Toolkit - Unified Workspace

## What's New

This workspace has been reorganized to use the new Unified GitHub PR Toolkit that consolidates all functionality into a single, powerful tool.

## Current Structure

`
Workspace/
+ GitHub-PR-Toolkit.ps1          # Main unified tool (USE THIS!)
+ Launch-Toolkit.ps1             # Simple launcher
+ UNIFIED-TOOLKIT-README.md      # Complete documentation
+ Legacy-Scripts/                 # Original scattered scripts (archive)
+ Results/                        # Operation results (auto-created)
+ Logs/                           # Log files (auto-created)
+ temp_repo_checkout/             # Default repository path
`

## Quick Start

### Interactive Mode (Recommended)
`powershell
.\Launch-Toolkit.ps1
`

### Direct Operations
`powershell
# Check status
.\Launch-Toolkit.ps1 -Operation 'status'

# Merge all PRs
.\Launch-Toolkit.ps1 -Operation 'merge'

# Force merge (aggressive)
.\Launch-Toolkit.ps1 -Operation 'force' -Force
`

## Documentation

- UNIFIED-TOOLKIT-README.md - Complete usage guide
- Legacy-Scripts/ - Original scripts for reference

## Important

- Use the new unified toolkit for all operations
- Legacy scripts are archived and no longer maintained
- The unified tool includes all functionality plus improvements
