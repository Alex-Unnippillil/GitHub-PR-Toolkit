# 🚀 GitHub PR Management Toolkit - Unified Edition

A comprehensive, consolidated PowerShell tool that combines all the functionality from the scattered scripts into one powerful, easy-to-use toolkit.

## ✨ **What's New**

- **Single Script**: All functionality in one `GitHub-PR-Toolkit.ps1` file
- **Interactive Menu**: User-friendly interface for all operations
- **Unified Logging**: Centralized logging and result tracking
- **Modular Design**: Organized functions by category
- **Safety Features**: Built-in confirmations and dry-run modes
- **Easy Configuration**: Centralized settings management

## 🎯 **Key Features**

### **Core Operations**
- 🔍 **Status Check**: View all open PRs and repository status
- 🔀 **Bulk Merge**: Merge all open PRs automatically
- ❌ **Bulk Close**: Close all open PRs (with confirmation)
- ⚡ **Force Merge**: Aggressive merging bypassing checks
- 🧹 **Repository Cleanup**: Clean up temporary files

### **Safety & Control**
- 🛡️ **Dry Run Mode**: Test operations without making changes
- ⚠️ **Force Mode**: Enable aggressive operations
- 📝 **Comprehensive Logging**: Track all operations
- 💾 **Result Storage**: Save operation results to JSON files
- 🔒 **Confirmation Prompts**: Prevent accidental operations

## 🚀 **Quick Start**

### **1. Basic Usage (Interactive Menu)**
```powershell
.\GitHub-PR-Toolkit.ps1 -GitHubToken "your_token_here"
```

### **2. Direct Operations**
```powershell
# Check status
.\GitHub-PR-Toolkit.ps1 -GitHubToken "your_token" -Operation "status"

# Merge all PRs
.\GitHub-PR-Toolkit.ps1 -GitHubToken "your_token" -Operation "merge"

# Close all PRs
.\GitHub-PR-Toolkit.ps1 -GitHubToken "your_token" -Operation "close"

# Force merge all PRs
.\GitHub-PR-Toolkit.ps1 -GitHubToken "your_token" -Operation "force"
```

### **3. Advanced Configuration**
```powershell
.\GitHub-PR-Toolkit.ps1 -GitHubToken "your_token" -DryRun -LocalRepoPath ".\my_repos" -MaxIterationsPerPR 20
```

## 📋 **Parameter Reference**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `GitHubToken` | string | ✅ Yes | - | Your GitHub personal access token |
| `LocalRepoPath` | string | ❌ No | `.\temp_repo_checkout` | Local path for repository operations |
| `DryRun` | switch | ❌ No | `$false` | Enable dry-run mode (no changes made) |
| `Force` | switch | ❌ No | `$false` | Enable force mode for aggressive operations |
| `MaxIterationsPerPR` | int | ❌ No | `10` | Maximum conflict resolution attempts per PR |
| `Operation` | string | ❌ No | `"menu"` | Direct operation: `status`, `merge`, `close`, `force` |

## 🎮 **Interactive Menu Guide**

### **Main Menu Options**

1. **Show Status** - Display current open PRs and repository status
2. **Merge All PRs** - Attempt to merge all open PRs using standard methods
3. **Close All PRs** - Close all open PRs (requires confirmation)
4. **Resolve Conflicts** - Handle merge conflicts for specific PRs
5. **Force Merge All** - Aggressive merging bypassing all checks
6. **Repository Cleanup** - Clean up temporary repository files
7. **Change Configuration** - Modify toolkit settings
8. **Exit** - Close the toolkit

### **Configuration Menu Options**

1. **Toggle Dry Run Mode** - Enable/disable dry-run mode
2. **Toggle Force Mode** - Enable/disable force operations
3. **Change Local Repository Path** - Set custom repository path
4. **Set Max Iterations Per PR** - Configure conflict resolution attempts
5. **Back to Main Menu** - Return to main menu

## 🔧 **Function Categories**

### **Core Utilities**
- `Write-Log` - Unified logging with file output
- `Invoke-GitHubAPI` - GitHub API wrapper with error handling
- `Get-GitHubUser` - Authentication and user verification
- `Get-UserPullRequests` - Fetch all open PRs

### **Repository Management**
- `Setup-Repository` - Clone/update repositories
- `Cleanup-Repository` - Remove temporary files

### **Conflict Resolution**
- `Resolve-MergeConflicts` - Handle merge conflicts automatically
- `Resolve-FileConflicts` - Fix individual file conflicts

### **PR Operations**
- `Merge-PullRequest` - Standard PR merging
- `Force-Merge-PullRequest` - Aggressive PR merging
- `Merge-AllPullRequests` - Bulk merge operations
- `Close-AllPullRequests` - Bulk close operations

### **Utilities**
- `Save-Results` - Store operation results
- `Show-Status` - Display current status
- Menu system functions

## 📁 **File Structure**

```
📁 Your Workspace/
├── 🚀 GitHub-PR-Toolkit.ps1          # Main unified tool
├── 📁 Results/                        # Operation results (auto-created)
├── 📁 Logs/                          # Log files (auto-created)
├── 📁 temp_repo_checkout/            # Default repository path
└── 📚 UNIFIED-TOOLKIT-README.md      # This documentation
```

## ⚠️ **Safety Features**

### **Built-in Protections**
- **Confirmation Prompts**: Critical operations require explicit confirmation
- **Dry Run Mode**: Test operations without making changes
- **Rate Limiting**: Built-in delays to respect GitHub API limits
- **Error Handling**: Comprehensive error catching and logging
- **Result Tracking**: All operations are logged and results saved

### **When to Use Each Mode**
- **Standard Mode**: Regular PR management and merging
- **Dry Run Mode**: Testing and validation
- **Force Mode**: Emergency situations requiring aggressive operations

## 🔍 **Troubleshooting**

### **Common Issues**

1. **Authentication Failed**
   - Verify your GitHub token has the necessary permissions
   - Check token expiration

2. **Repository Access Denied**
   - Ensure token has access to the repositories
   - Check repository visibility settings

3. **Merge Conflicts**
   - Use conflict resolution functions
   - Consider force mode for complex conflicts

4. **Rate Limiting**
   - The tool includes built-in delays
   - Increase delays if needed

### **Debug Mode**
Enable detailed logging by checking the `Logs/` directory for detailed operation logs.

## 🚨 **Important Notes**

- **Backup First**: Always backup important repositories before using aggressive operations
- **Test Environment**: Use dry-run mode in production environments first
- **Token Security**: Keep your GitHub token secure and never commit it to version control
- **Repository Permissions**: Ensure your token has the necessary repository permissions

## 📈 **Performance Tips**

- **Batch Operations**: Use bulk operations for multiple PRs
- **Local Paths**: Use fast local storage for repository operations
- **Network**: Ensure stable internet connection for GitHub API calls
- **Timing**: Run during off-peak hours for large operations

## 🔄 **Migration from Old Scripts**

### **What's Consolidated**
- ✅ All PR management functions
- ✅ Conflict resolution tools
- ✅ Repository maintenance
- ✅ Bulk operations
- ✅ Logging and results

### **What's Improved**
- 🚀 Single entry point
- 🎯 Interactive menu system
- 📝 Unified logging
- ⚙️ Centralized configuration
- 🛡️ Enhanced safety features

## 📞 **Support**

For issues or questions:
1. Check the logs in the `Logs/` directory
2. Review the operation results in the `Results/` directory
3. Use dry-run mode to test operations
4. Check GitHub API status and rate limits

---

**🎉 Welcome to the Unified GitHub PR Toolkit!** 

This tool consolidates years of GitHub automation experience into one powerful, safe, and easy-to-use solution.
