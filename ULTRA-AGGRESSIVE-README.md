# 💀 Ultra-Aggressive PR Merger 💀

## ⚠️ EXTREME WARNING ⚠️

**This tool will OBLITERATE any code that prevents pull requests from merging. Use with extreme caution!**

## What This Tool Does

The Ultra-Aggressive PR Merger is the most aggressive version of the conflict resolution tools. It:

1. **🎯 Attempts to merge each PR first** - tries to merge without changes
2. **💀 If merge fails, OBLITERATES problematic code** - removes any lines that could cause conflicts
3. **💾 Commits and pushes the obliteration** - saves the changes to the PR branch
4. **🔄 Retries the merge** - attempts to merge again after removing code
5. **🔥 Increases aggression level** - if still fails, removes even MORE code patterns
6. **♻️ Repeats until success** - continues this cycle until the PR merges or max iterations reached
7. **➡️ Moves to next PR** - processes each PR individually until all are merged

## 🔥 Aggression Levels

The tool uses **10 increasing levels of aggression**:

1. **Level 1**: Critical merge conflicts only (`<<<<<<< HEAD`, `=======`, etc.)
2. **Level 2**: + Code quality issues (`console.log`, `debugger`, TODO comments)
3. **Level 3**: + Syntax issues (duplicate semicolons, empty functions)
4. **Level 4**: + Test artifacts (`.only`, `.skip`, focused tests)
5. **Level 5**: + Import/export issues (empty imports, malformed requires)
6. **Level 6**: + Error messages (build failures, module not found)
7. **Level 7**: + Version control artifacts (`.orig`, `.bak`, merge conflict files)
8. **Level 8**: + Problematic comments (conflict markers in comments)
9. **Level 9**: + Empty blocks (empty if statements, try/catch blocks)
10. **Level 10**: + Nuclear option (removes almost anything suspicious)

## Usage

### Basic Usage
```powershell
.\ultra-aggressive-pr-merger.ps1 -GitHubToken "your_github_token_here"
```

### With Runner Script
```powershell
.\run-ultra-aggressive-merger.ps1 -GitHubToken "your_github_token_here"
```

### Dry Run (Recommended First)
```powershell
.\ultra-aggressive-pr-merger.ps1 -GitHubToken "your_token" -DryRun
```

### Custom Max Iterations
```powershell
.\ultra-aggressive-pr-merger.ps1 -GitHubToken "your_token" -MaxIterationsPerPR 15
```

## Parameters

- **`-GitHubToken`** (Required): Your GitHub personal access token
- **`-DryRun`** (Optional): Show what would be obliterated without making changes
- **`-LocalRepoPath`** (Optional): Path for temporary repo checkouts (default: `.\temp_repo_checkout`)
- **`-MaxIterationsPerPR`** (Optional): Maximum obliteration iterations per PR (default: 10)

## 🛡️ Safety Features

1. **Dry Run Mode**: Always test with `-DryRun` first
2. **Confirmation Required**: Must type `OBLITERATE` to confirm in live mode
3. **Detailed Logging**: Shows exactly what code is being removed
4. **Results Tracking**: Saves detailed results to JSON file
5. **Per-PR Processing**: Each PR is processed individually

## What Gets Obliterated

The tool will remove **ANY** lines that match these patterns:

### 🚨 Always Removed (Level 1+)
- Merge conflict markers (`<<<<<<< HEAD`, `=======`, `>>>>>>>`)
- Git conflict resolution markers

### 🔧 Code Quality Issues (Level 2+)
- `console.log()`, `debugger`, `alert()` statements
- TODO, FIXME, HACK comments
- Trailing whitespace

### ⚠️ Syntax Problems (Level 3+)
- Multiple semicolons (`;;`)
- Empty function definitions
- Malformed code blocks

### 🧪 Test Issues (Level 4+)
- Focused tests (`.only`, `fit`, `fdescribe`)
- Skipped tests (`.skip`, `xit`, `xdescribe`)

### 📦 Import Problems (Level 5+)
- Empty import statements
- Malformed require() calls
- Broken export statements

### And Much More...

Each level removes increasingly more code patterns until the PR can merge successfully.

## Example Output

```
💀 ULTRA-AGGRESSIVE PR MERGER 💀
===============================

🔄 ITERATION #1 - Aggression Level: 1
🔍 Scanning for problems at aggression level 1...
💀 Found 5 problems to obliterate
💀 REMOVING 5 problematic lines...
   🔥 Nuking 5 lines from src/app.js
     ❌ Obliterating line 42: <<<<<<< HEAD
     ❌ Obliterating line 45: =======
     ❌ Obliterating line 48: >>>>>>> feature-branch
💾 Committing obliteration...
📤 Force pushing obliteration...
🚀 MERGE ATTEMPT #1...
   🎉 SUCCESS! Merged using squash on attempt 1!
```

## Results

After completion, you'll get:
- **Console summary** with success/failure counts
- **JSON results file** with detailed information
- **URLs for manual review** if any PRs fail to merge

## ⚠️ Important Notes

1. **BACKUP YOUR REPOSITORIES** before running this tool
2. **This will permanently delete code** that prevents merging
3. **Use DRY RUN first** to see what would be removed
4. **Some code removal may break functionality** - review merged PRs
5. **This tool prioritizes merging over code preservation**

## When to Use This Tool

Use when:
- ✅ You have many PRs with merge conflicts
- ✅ You need to merge PRs quickly and don't mind losing some code
- ✅ The code being removed is likely non-essential (debug statements, TODO comments, etc.)
- ✅ You're willing to fix any broken functionality after merging

**Don't use when:**
- ❌ The PRs contain important changes that shouldn't be modified
- ❌ You need to preserve exact commit history
- ❌ The repositories contain critical production code
- ❌ You haven't reviewed what code patterns will be removed

## 🔒 Security

The tool requires a GitHub personal access token with:
- `repo` permissions (to read and merge PRs)
- `workflow` permissions (if modifying workflow files)

## Comparison with Other Tools

| Tool | Aggression Level | Iterations | Target |
|------|------------------|------------|---------|
| `conflict-fixer.ps1` | Low | Single pass | Basic conflicts |
| `aggressive-conflict-resolver.ps1` | Medium | Single pass | More patterns |
| `auto-fix-and-merge-prs.ps1` | Medium | Single pass | Targeted fixing |
| **`ultra-aggressive-pr-merger.ps1`** | **Ultra High** | **Up to 10** | **Everything until merge** |

## Support

This tool is experimental and aggressive. Use at your own risk and always:
1. Run with `-DryRun` first
2. Backup your repositories
3. Review merged PRs for functionality
4. Be prepared to restore code if needed

---

💀 **Remember: This tool prioritizes successful merging over code preservation!** 💀
