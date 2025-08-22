# 🚀 Quick Start Guide - GitHub PR Toolkit

## ⚡ **Get Started in 3 Steps**

### **Step 1: Get Your GitHub Token**
1. Go to [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give it a name like "PR Toolkit"
4. Select these permissions:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
5. Click "Generate token" and copy it

### **Step 2: Run the Toolkit**
```powershell
# Interactive mode (recommended for beginners)
.\Launch-Toolkit.ps1

# Or run directly with your token
.\GitHub-PR-Toolkit.ps1 -GitHubToken "your_token_here"
```

### **Step 3: Choose Your Operation**
- **Option 1**: Use the interactive menu (easiest)
- **Option 2**: Run direct commands

## 🎯 **Common Use Cases**

### **Check What PRs You Have Open**
```powershell
.\Launch-Toolkit.ps1 -Operation "status"
```

### **Merge All Your Open PRs**
```powershell
.\Launch-Toolkit.ps1 -Operation "merge"
```

### **Close All Your Open PRs**
```powershell
.\Launch-Toolkit.ps1 -Operation "close"
```

### **Force Merge (Aggressive)**
```powershell
.\Launch-Toolkit.ps1 -Operation "force" -Force
```

## 🛡️ **Safety First**

### **Test Mode (Recommended)**
```powershell
# See what would happen without making changes
.\Launch-Toolkit.ps1 -DryRun
```

### **Interactive Confirmation**
- The toolkit will ask for confirmation before dangerous operations
- Type `YES` when prompted to confirm

## 📚 **Need More Help?**

- **Complete Guide**: `UNIFIED-TOOLKIT-README.md`
- **Interactive Help**: Run the toolkit and explore the menu
- **Dry Run**: Use `-DryRun` to test safely

## ⚠️ **Important Notes**

- **Backup First**: Always backup important repositories
- **Test Environment**: Use dry-run mode first
- **Token Security**: Keep your token secure
- **Permissions**: Ensure token has necessary repository access

---

**🎉 You're Ready to Go!** 

Start with the interactive menu to explore all features safely.
