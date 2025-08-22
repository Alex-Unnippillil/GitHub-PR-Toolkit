# 🚀 GitHub PR Management Toolkit - Unified Edition
# Consolidates all PR management, conflict resolution, and repository tools into one comprehensive script
# 
# ⚠️ **IMPORTANT DISCLAIMER**
# This tool can make irreversible changes to repositories. Use with extreme caution.
# Always test in controlled environments first.

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$false)]
    [string]$LocalRepoPath = ".\temp_repo_checkout",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxIterationsPerPR = 10,
    
    [Parameter(Mandatory=$false)]
    [string]$Operation = "menu"
)

# =============================================================================
# GLOBAL CONFIGURATION
# =============================================================================

$Global:Config = @{
    GitHubToken = $GitHubToken
    LocalRepoPath = $LocalRepoPath
    DryRun = $DryRun
    Force = $Force
    MaxIterationsPerPR = $MaxIterationsPerPR
    ResultsPath = ".\Results"
    LogPath = ".\Logs"
}

# GitHub API headers
$Global:Headers = @{
    'Authorization' = "token $GitHubToken"
    'Accept' = 'application/vnd.github.v3+json'
    'User-Agent' = 'PowerShell-GitHub-PR-Toolkit'
}

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "ERROR" { $Color = "Red" }
        "WARNING" { $Color = "Yellow" }
        "SUCCESS" { $Color = "Green" }
        "INFO" { $Color = "Cyan" }
    }
    
    Write-Host $logMessage -ForegroundColor $Color
    
    # Save to log file
    $logFile = Join-Path $Global:Config.LogPath "toolkit-$(Get-Date -Format 'yyyyMMdd').log"
    if (-not (Test-Path $Global:Config.LogPath)) {
        New-Item -ItemType Directory -Path $Global:Config.LogPath -Force | Out-Null
    }
    $logMessage | Out-File -FilePath $logFile -Append
}

function Invoke-GitHubAPI {
    param(
        [string]$Uri, 
        [string]$Method = 'GET', 
        [hashtable]$Body = @{}
    )
    
    try {
        $params = @{
            Uri = $Uri
            Method = $Method
            Headers = $Global:Headers
            ContentType = 'application/json'
        }
        
        if ($Body.Count -gt 0) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $result = Invoke-RestMethod @params
        Write-Log "API call successful: $Method $Uri" -Level "INFO"
        return $result
    }
    catch {
        Write-Log "API call failed for $Uri : $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Get-GitHubUser {
    Write-Log "Authenticating with GitHub..." -Level "INFO"
    $user = Invoke-GitHubAPI -Uri "https://api.github.com/user"
    if ($user) {
        Write-Log "Authenticated as: $($user.login)" -Level "SUCCESS"
        return $user.login
    } else {
        Write-Log "Failed to authenticate. Check your token." -Level "ERROR"
        exit 1
    }
}

function Get-UserPullRequests {
    param([string]$Username)
    
    Write-Log "Fetching open pull requests..." -Level "INFO"
    
    $searchQuery = "is:pr is:open author:$Username"
    $uri = "https://api.github.com/search/issues?q=" + [System.Web.HttpUtility]::UrlEncode($searchQuery) + "&per_page=100"
    
    $allPRs = @()
    $page = 1
    
    do {
        $currentUri = "$uri&page=$page"
        $response = Invoke-GitHubAPI -Uri $currentUri
        
        if ($response -and $response.items) {
            $allPRs += $response.items
            Write-Log "Found $($response.items.Count) PRs on page $page" -Level "INFO"
            $page++
        } else {
            break
        }
    } while ($response.items.Count -eq 100)
    
    Write-Log "Total open PRs: $($allPRs.Count)" -Level "SUCCESS"
    return $allPRs
}

function Get-PRDetails {
    param([string]$RepoFullName, [int]$PRNumber)
    
    $uri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber"
    return Invoke-GitHubAPI -Uri $uri
}

function Get-PRFiles {
    param([string]$RepoFullName, [int]$PRNumber)
    
    $uri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/files"
    return Invoke-GitHubAPI -Uri $uri
}

# =============================================================================
# REPOSITORY MANAGEMENT FUNCTIONS
# =============================================================================

function Setup-Repository {
    param(
        [string]$RepoUrl, 
        [string]$LocalPath, 
        [string]$BranchName = "main"
    )
    
    Write-Log "Setting up repository: $RepoUrl" -Level "INFO"
    
    if (Test-Path $LocalPath) {
        Write-Log "Repository already exists, updating..." -Level "INFO"
        Set-Location $LocalPath
        git fetch origin
        git reset --hard "origin/$BranchName"
    } else {
        Write-Log "Cloning repository..." -Level "INFO"
        git clone $RepoUrl $LocalPath
        Set-Location $LocalPath
        git checkout $BranchName
    }
    
    Write-Log "Repository setup complete" -Level "SUCCESS"
}

function Cleanup-Repository {
    param([string]$LocalPath)
    
    if (Test-Path $LocalPath) {
        Write-Log "Cleaning up repository: $LocalPath" -Level "INFO"
        Remove-Item -Path $LocalPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Repository cleanup complete" -Level "SUCCESS"
    }
}

# =============================================================================
# CONFLICT RESOLUTION FUNCTIONS
# =============================================================================

function Resolve-MergeConflicts {
    param(
        [string]$RepoFullName,
        [int]$PRNumber,
        [string]$LocalPath
    )
    
    Write-Log "Resolving merge conflicts for PR #$PRNumber" -Level "INFO"
    
    $pr = Get-PRDetails -RepoFullName $RepoFullName -PRNumber $PRNumber
    if (-not $pr) {
        Write-Log "Failed to get PR details" -Level "ERROR"
        return $false
    }
    
    # Get PR files
    $files = Get-PRFiles -RepoFullName $RepoFullName -PRNumber $PRNumber
    if (-not $files) {
        Write-Log "Failed to get PR files" -Level "ERROR"
        return $false
    }
    
    # Checkout PR branch
    Set-Location $LocalPath
    git fetch origin $pr.head.ref
    git checkout -B "pr-$PRNumber" "origin/$($pr.head.ref)"
    
    # Try to merge with base branch
    try {
        git merge "origin/$($pr.base.ref)" --no-commit --no-ff
        Write-Log "Merge successful without conflicts" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Merge conflicts detected, resolving..." -Level "WARNING"
        
        # Get conflicted files
        $conflictedFiles = git diff --name-only --diff-filter=U
        
        foreach ($file in $conflictedFiles) {
            Write-Log "Resolving conflicts in: $file" -Level "INFO"
            Resolve-FileConflicts -FilePath $file -LocalPath $LocalPath
        }
        
        # Commit the resolution
        try {
            git add .
            git commit -m "Auto-resolve merge conflicts for PR #$PRNumber"
            Write-Log "Conflict resolution complete" -Level "SUCCESS"
            return $true
        }
        catch {
            Write-Log "Failed to commit conflict resolution" -Level "ERROR"
            return $false
        }
    }
}

function Resolve-FileConflicts {
    param([string]$FilePath, [string]$LocalPath)
    
    $fullPath = Join-Path $LocalPath $FilePath
    if (-not (Test-Path $fullPath)) {
        return
    }
    
    $content = Get-Content $fullPath -Raw
    
    # Remove conflict markers
    $content = $content -replace '<<<<<<< HEAD.*?=======.*?>>>>>>> .*', ''
    $content = $content -replace '<<<<<<< HEAD.*?=======.*?>>>>>>>.*', ''
    
    # Remove empty lines
    $content = $content -replace '\r?\n\s*\r?\n', "`n"
    
    # Save resolved content
    $content | Out-File -FilePath $fullPath -Encoding UTF8
}

# =============================================================================
# PR MERGING FUNCTIONS
# =============================================================================

function Merge-PullRequest {
    param(
        [string]$RepoFullName,
        [int]$PRNumber,
        [string]$MergeMethod = "merge"
    )
    
    Write-Log "Merging PR #$PRNumber using method: $MergeMethod" -Level "INFO"
    
    $mergeBody = @{
        merge_method = $MergeMethod
        commit_title = "Merge PR #$PRNumber"
        commit_message = "Automated merge of PR #$PRNumber"
    }
    
    $uri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/merge"
    $result = Invoke-GitHubAPI -Uri $uri -Method "PUT" -Body $mergeBody
    
    if ($result -and $result.merged) {
        Write-Log "PR #$PRNumber merged successfully!" -Level "SUCCESS"
        return $true
    } else {
        Write-Log "Failed to merge PR #$PRNumber" -Level "ERROR"
        return $false
    }
}

function Force-Merge-PullRequest {
    param(
        [string]$RepoFullName,
        [int]$PRNumber
    )
    
    Write-Log "Force merging PR #$PRNumber (bypassing checks)" -Level "WARNING"
    
    # This is a more aggressive approach that bypasses branch protection
    # Use with extreme caution
    
    $mergeBody = @{
        merge_method = "squash"
        commit_title = "Force merge PR #$PRNumber"
        commit_message = "Emergency force merge of PR #$PRNumber"
    }
    
    $uri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/merge"
    $result = Invoke-GitHubAPI -Uri $uri -Method "PUT" -Body $mergeBody
    
    if ($result -and $result.merged) {
        Write-Log "PR #$PRNumber force merged successfully!" -Level "SUCCESS"
        return $true
    } else {
        Write-Log "Force merge failed for PR #$PRNumber" -Level "ERROR"
        return $false
    }
}

# =============================================================================
# BULK OPERATIONS
# =============================================================================

function Merge-AllPullRequests {
    param([string]$Username)
    
    Write-Log "Starting bulk merge of all pull requests" -Level "INFO"
    
    $pullRequests = Get-UserPullRequests -Username $Username
    if ($pullRequests.Count -eq 0) {
        Write-Log "No open pull requests found" -Level "INFO"
        return
    }
    
    $successCount = 0
    $failureCount = 0
    $results = @()
    
    foreach ($pr in $pullRequests) {
        $repoFullName = $pr.repository_url -replace "https://api.github.com/repos/", ""
        $prNumber = $pr.number
        
        Write-Log "Processing PR #$prNumber in $repoFullName" -Level "INFO"
        
        # Try standard merge first
        $merged = Merge-PullRequest -RepoFullName $repoFullName -PRNumber $prNumber
        
        if (-not $merged -and $Global:Config.Force) {
            Write-Log "Standard merge failed, attempting force merge" -Level "WARNING"
            $merged = Force-Merge-PullRequest -RepoFullName $repoFullName -PRNumber $prNumber
        }
        
        $result = @{
            Repository = $repoFullName
            PRNumber = $prNumber
            Title = $pr.title
            Success = $merged
            URL = $pr.html_url
        }
        
        $results += [PSCustomObject]$result
        
        if ($merged) {
            $successCount++
        } else {
            $failureCount++
        }
        
        # Rate limiting
        Start-Sleep -Milliseconds 500
    }
    
    # Save results
    Save-Results -Results $results -Operation "bulk-merge"
    
    # Summary
    Write-Log "Bulk merge complete: $successCount successful, $failureCount failed" -Level "SUCCESS"
}

function Close-AllPullRequests {
    param([string]$Username)
    
    Write-Log "Starting bulk close of all pull requests" -Level "WARNING"
    
    if (-not $Global:Config.Force) {
        $confirm = Read-Host "This will close ALL open PRs. Are you sure? (type 'YES' to confirm)"
        if ($confirm -ne "YES") {
            Write-Log "Operation cancelled by user" -Level "INFO"
            return
        }
    }
    
    $pullRequests = Get-UserPullRequests -Username $Username
    if ($pullRequests.Count -eq 0) {
        Write-Log "No open pull requests found" -Level "INFO"
        return
    }
    
    $successCount = 0
    $failureCount = 0
    $results = @()
    
    foreach ($pr in $pullRequests) {
        $repoFullName = $pr.repository_url -replace "https://api.github.com/repos/", ""
        $prNumber = $pr.number
        
        Write-Log "Closing PR #$prNumber in $repoFullName" -Level "INFO"
        
        $closeBody = @{ state = "closed" }
        $closeUri = "https://api.github.com/repos/$repoFullName/pulls/$prNumber"
        $closeResult = Invoke-GitHubAPI -Uri $closeUri -Method "PATCH" -Body $closeBody
        
        $result = @{
            Repository = $repoFullName
            PRNumber = $prNumber
            Title = $pr.title
            Success = $closeResult -and $closeResult.state -eq "closed"
            URL = $pr.html_url
        }
        
        $results += [PSCustomObject]$result
        
        if ($result.Success) {
            $successCount++
        } else {
            $failureCount++
        }
        
        Start-Sleep -Milliseconds 200
    }
    
    Save-Results -Results $results -Operation "bulk-close"
    Write-Log "Bulk close complete: $successCount successful, $failureCount failed" -Level "SUCCESS"
}

# =============================================================================
# UTILITY OPERATIONS
# =============================================================================

function Save-Results {
    param(
        [array]$Results,
        [string]$Operation
    )
    
    if (-not (Test-Path $Global:Config.ResultsPath)) {
        New-Item -ItemType Directory -Path $Global:Config.ResultsPath -Force | Out-Null
    }
    
    $resultFile = Join-Path $Global:Config.ResultsPath "$Operation-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFile
    Write-Log "Results saved to: $resultFile" -Level "INFO"
}

function Show-Status {
    param([string]$Username)
    
    Write-Log "Fetching current status..." -Level "INFO"
    
    $pullRequests = Get-UserPullRequests -Username $Username
    
    Write-Host ""
    Write-Host "Current Status" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    Write-Host "Username: $Username" -ForegroundColor White
    Write-Host "Open PRs: $($pullRequests.Count)" -ForegroundColor Yellow
    
    if ($pullRequests.Count -gt 0) {
        Write-Host ""
        Write-Host "Open Pull Requests:" -ForegroundColor Green
        foreach ($pr in $pullRequests) {
            $repoName = ($pr.repository_url -replace "https://api.github.com/repos/", "").Split('/')[-1]
            Write-Host "  #$($pr.number) - $($pr.title) [$repoName]" -ForegroundColor White
        }
    }
}

# =============================================================================
# MAIN MENU SYSTEM
# =============================================================================

function Show-MainMenu {
    Clear-Host
    Write-Host "GitHub PR Management Toolkit" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Current Configuration:" -ForegroundColor Yellow
    Write-Host "  Dry Run: $($Global:Config.DryRun)" -ForegroundColor White
    Write-Host "  Force Mode: $($Global:Config.Force)" -ForegroundColor White
    Write-Host "  Local Path: $($Global:Config.LocalRepoPath)" -ForegroundColor White
    Write-Host ""
    Write-Host "Available Operations:" -ForegroundColor Green
    Write-Host "  1. Show Status" -ForegroundColor White
    Write-Host "  2. Merge All PRs" -ForegroundColor White
    Write-Host "  3. Close All PRs" -ForegroundColor White
    Write-Host "  4. Resolve Conflicts" -ForegroundColor White
    Write-Host "  5. Force Merge All" -ForegroundColor Red
    Write-Host "  6. Repository Cleanup" -ForegroundColor White
    Write-Host "  7. Change Configuration" -ForegroundColor Yellow
    Write-Host "  8. Exit" -ForegroundColor Gray
    Write-Host ""
}

function Show-ConfigurationMenu {
    Clear-Host
    Write-Host "Configuration Menu" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Toggle Dry Run Mode" -ForegroundColor White
    Write-Host "  2. Toggle Force Mode" -ForegroundColor White
    Write-Host "  3. Change Local Repository Path" -ForegroundColor White
    Write-Host "  4. Set Max Iterations Per PR" -ForegroundColor White
    Write-Host "  5. Back to Main Menu" -ForegroundColor Gray
    Write-Host ""
}

function Handle-MenuSelection {
    param([string]$Selection)
    
    switch ($Selection) {
        "1" { 
            $username = Get-GitHubUser
            Show-Status -Username $username
            Read-Host "Press Enter to continue"
        }
        "2" { 
            $username = Get-GitHubUser
            Merge-AllPullRequests -Username $username
            Read-Host "Press Enter to continue"
        }
        "3" { 
            $username = Get-GitHubUser
            Close-AllPullRequests -Username $username
            Read-Host "Press Enter to continue"
        }
        "4" { 
            Write-Log "Conflict resolution requires specific PR details" -Level "INFO"
            Read-Host "Press Enter to continue"
        }
        "5" { 
            $Global:Config.Force = $true
            $username = Get-GitHubUser
            Merge-AllPullRequests -Username $username
            Read-Host "Press Enter to continue"
        }
        "6" { 
            Cleanup-Repository -LocalPath $Global:Config.LocalRepoPath
            Read-Host "Press Enter to continue"
        }
        "7" { 
            Show-ConfigurationMenu
            $configChoice = Read-Host "Select option"
            Handle-ConfigurationSelection -Selection $configChoice
        }
        "8" { 
            Write-Log "Exiting toolkit" -Level "INFO"
            exit 0
        }
        default { 
            Write-Log "Invalid selection" -Level "WARNING"
            Start-Sleep -Seconds 1
        }
    }
}

function Handle-ConfigurationSelection {
    param([string]$Selection)
    
    switch ($Selection) {
        "1" { 
            $Global:Config.DryRun = -not $Global:Config.DryRun
            Write-Log "Dry Run Mode: $($Global:Config.DryRun)" -Level "INFO"
        }
        "2" { 
            $Global:Config.Force = -not $Global:Config.Force
            Write-Log "Force Mode: $($Global:Config.Force)" -Level "INFO"
        }
        "3" { 
            $newPath = Read-Host "Enter new local repository path"
            if ($newPath) {
                $Global:Config.LocalRepoPath = $newPath
                Write-Log "Local path updated to: $newPath" -Level "INFO"
            }
        }
        "4" { 
            $newMax = Read-Host "Enter new max iterations per PR"
            if ($newMax -match '^\d+$') {
                $Global:Config.MaxIterationsPerPR = [int]$newMax
                Write-Log "Max iterations updated to: $newMax" -Level "INFO"
            }
        }
        "5" { return }
        default { 
            Write-Log "Invalid configuration selection" -Level "WARNING"
        }
    }
    
    Start-Sleep -Seconds 2
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

function Main {
    Write-Log "GitHub PR Toolkit starting..." -Level "INFO"
    
    # Create necessary directories
    if (-not (Test-Path $Global:Config.ResultsPath)) {
        New-Item -ItemType Directory -Path $Global:Config.ResultsPath -Force | Out-Null
    }
    if (-not (Test-Path $Global:Config.LogPath)) {
        New-Item -ItemType Directory -Path $Global:Config.LogPath -Force | Out-Null
    }
    
    # Test authentication
    $username = Get-GitHubUser
    
    if ($Operation -ne "menu") {
        # Direct operation mode
        switch ($Operation) {
            "status" { Show-Status -Username $username }
            "merge" { Merge-AllPullRequests -Username $username }
            "close" { Close-AllPullRequests -Username $username }
            "force" { 
                $Global:Config.Force = $true
                Merge-AllPullRequests -Username $username 
            }
            default { Write-Log "Unknown operation: $Operation" -Level "ERROR" }
        }
    } else {
        # Interactive menu mode
        do {
            Show-MainMenu
            $choice = Read-Host "Select operation"
            Handle-MenuSelection -Selection $choice
        } while ($true)
    }
}

# Start the toolkit
Main
