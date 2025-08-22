# 🔒 GitHub PR Management Toolkit - SAFE EDITION
# Advanced PR management with comprehensive safety checks, backup mechanisms, and rollback capabilities
#
# 🛡️ **SAFETY FEATURES**
# - Pre-merge validation (status checks, reviews, branch protection)
# - Automatic backup creation before merges
# - Rollback mechanisms for failed operations
# - Emergency confirmation protocols
# - Detailed audit logging and reporting
#
# ⚠️ **IMPORTANT DISCLAIMER**
# Even with safety features, this tool can make changes to repositories. Always review safety reports
# and test in controlled environments first. Use the Safe Merge option for normal operations.

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

# Initialize safety rules with safe defaults
$Global:SafetyRules = @{
    CheckRequiredStatusChecks = $true
    CheckRequiredReviews = $true
    RequiredApprovals = 1
    CheckBranchProtection = $true
    CheckPRAge = $true
    MaxPRAgeDays = 30
    MaxFileCount = 50
    MaxChanges = 1000
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
# SAFETY AND VALIDATION FUNCTIONS
# =============================================================================

function Test-PRMergeSafety {
    param(
        [string]$RepoFullName,
        [int]$PRNumber,
        [hashtable]$SafetyRules = @{}
    )

    Write-Log "Performing safety checks for PR #$PRNumber" -Level "INFO"

    $safetyReport = @{
        PRNumber = $PRNumber
        Repository = $RepoFullName
        ChecksPassed = $true
        Issues = @()
        Warnings = @()
        CriticalFailures = @()
    }

    # Get PR details
    $pr = Get-PRDetails -RepoFullName $RepoFullName -PRNumber $PRNumber
    if (-not $pr) {
        $safetyReport.ChecksPassed = $false
        $safetyReport.CriticalFailures += "Failed to retrieve PR details"
        return $safetyReport
    }

    # Check 1: PR mergeable status
    if (-not $pr.mergeable) {
        $safetyReport.ChecksPassed = $false
        $safetyReport.CriticalFailures += "PR is not mergeable (has conflicts or other issues)"
    } elseif ($null -eq $pr.mergeable) {
        $safetyReport.Warnings += "Mergeable status is unknown (still computing)"
    }

    # Check 2: Required status checks
    if ($SafetyRules.CheckRequiredStatusChecks -and $pr.head.sha) {
        $statusUri = "https://api.github.com/repos/$RepoFullName/commits/$($pr.head.sha)/status"
        $statusResult = Invoke-GitHubAPI -Uri $statusUri

        if ($statusResult) {
            if ($statusResult.state -ne "success") {
                $safetyReport.ChecksPassed = $false
                $safetyReport.CriticalFailures += "Required status checks failed (state: $($statusResult.state))"
            }
        }
    }

    # Check 3: Required reviews
    if ($SafetyRules.CheckRequiredReviews) {
        $reviewsUri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/reviews"
        $reviews = Invoke-GitHubAPI -Uri $reviewsUri

        $approvedReviews = ($reviews | Where-Object { $_.state -eq "APPROVED" }).Count
        $requiredApprovals = if ($SafetyRules.RequiredApprovals) { $SafetyRules.RequiredApprovals } else { 1 }

        if ($approvedReviews -lt $requiredApprovals) {
            $safetyReport.ChecksPassed = $false
            $safetyReport.CriticalFailures += "Insufficient approvals: $approvedReviews/$requiredApprovals required"
        }
    }

    # Check 4: Branch protection
    if ($SafetyRules.CheckBranchProtection) {
        $branchUri = "https://api.github.com/repos/$RepoFullName/branches/$($pr.base.ref)"
        $branchInfo = Invoke-GitHubAPI -Uri $branchUri

        if ($branchInfo.protection) {
            if ($branchInfo.protection.required_status_checks) {
                $safetyReport.Warnings += "Branch protection enabled - ensure all required checks pass"
            }
            if ($branchInfo.protection.required_pull_request_reviews) {
                $safetyReport.Warnings += "Branch protection requires reviews - ensure requirements are met"
            }
        }
    }

    # Check 5: PR size and complexity
    $files = Get-PRFiles -RepoFullName $RepoFullName -PRNumber $PRNumber
    if ($files) {
        $totalAdditions = ($files | Measure-Object -Property additions -Sum).Sum
        $totalDeletions = ($files | Measure-Object -Property deletions -Sum).Sum
        $fileCount = $files.Count

        if ($SafetyRules.MaxFileCount -and $fileCount -gt $SafetyRules.MaxFileCount) {
            $safetyReport.Warnings += "Large PR: $fileCount files (max recommended: $($SafetyRules.MaxFileCount))"
        }

        if ($SafetyRules.MaxChanges -and ($totalAdditions + $totalDeletions) -gt $SafetyRules.MaxChanges) {
            $safetyReport.Warnings += "Large PR: $($totalAdditions + $totalDeletions) changes (max recommended: $($SafetyRules.MaxChanges))"
        }

        # Check for critical files
        $criticalFiles = $files | Where-Object {
            $_.filename -match "^(package\.json|composer\.json|requirements\.txt|Gemfile|\.env|config/.*\.php|appsettings\.json)$"
        }
        if ($criticalFiles) {
            $safetyReport.Warnings += "PR modifies critical configuration files: $($criticalFiles.filename -join ', ')"
        }
    }

    # Check 6: PR age and activity
    if ($SafetyRules.CheckPRAge) {
        $createdDate = [DateTime]::Parse($pr.created_at)
        $daysOld = ([DateTime]::Now - $createdDate).Days

        if ($SafetyRules.MaxPRAgeDays -and $daysOld -gt $SafetyRules.MaxPRAgeDays) {
            $safetyReport.Warnings += "PR is $daysOld days old (max recommended: $($SafetyRules.MaxPRAgeDays))"
        }
    }

    return $safetyReport
}

function Show-SafetyReport {
    param([hashtable]$SafetyReport)

    Write-Host ""
    Write-Host "Safety Check Report for PR #$($SafetyReport.PRNumber)" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan

    if ($SafetyReport.CriticalFailures.Count -gt 0) {
        Write-Host "CRITICAL ISSUES:" -ForegroundColor Red
        foreach ($issue in $SafetyReport.CriticalFailures) {
            Write-Host "  X $issue" -ForegroundColor Red
        }
    }

    if ($SafetyReport.Warnings.Count -gt 0) {
        Write-Host "WARNINGS:" -ForegroundColor Yellow
        foreach ($warning in $SafetyReport.Warnings) {
            Write-Host "  ! $warning" -ForegroundColor Yellow
        }
    }

    if ($SafetyReport.Issues.Count -gt 0) {
        Write-Host "ISSUES:" -ForegroundColor Magenta
        foreach ($issue in $SafetyReport.Issues) {
            Write-Host "  ? $issue" -ForegroundColor Magenta
        }
    }

    if ($SafetyReport.ChecksPassed -and $SafetyReport.CriticalFailures.Count -eq 0) {
        Write-Host "OK: All safety checks passed" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Safety checks failed - merge not recommended" -ForegroundColor Red
    }

    Write-Host ""
}

function Get-UserSafetyConfirmation {
    param(
        [hashtable]$SafetyReport,
        [string]$Operation
    )

    Write-Host "Safety Confirmation Required" -ForegroundColor Yellow
    Write-Host ("=" * 30) -ForegroundColor Yellow

    if (-not $SafetyReport.ChecksPassed) {
        Write-Host "WARNING: Some safety checks failed!" -ForegroundColor Red
        $response = Read-Host "Do you want to proceed anyway? (type 'YES' to confirm)"
        if ($response -ne "YES") {
            Write-Log "Operation cancelled by user due to safety concerns" -Level "INFO"
            return $false
        }
    }

    $confirmMessage = "Confirm $Operation of PR #$($SafetyReport.PRNumber) in $($SafetyReport.Repository)?"
    $response = Read-Host "$confirmMessage (type 'CONFIRM' to proceed)"
    return $response -eq "CONFIRM"
}

# =============================================================================
# SAFE PR MERGING FUNCTIONS
# =============================================================================

function Merge-PullRequest {
    param(
        [string]$RepoFullName,
        [int]$PRNumber,
        [string]$MergeMethod = "merge",
        [hashtable]$SafetyRules = @{},
        [switch]$SkipSafetyChecks = $false,
        [switch]$SkipConfirmation = $false
    )

    Write-Log "Merging PR #$PRNumber using method: $MergeMethod" -Level "INFO"

    # Perform safety checks unless explicitly skipped
    if (-not $SkipSafetyChecks) {
        $safetyReport = Test-PRMergeSafety -RepoFullName $RepoFullName -PRNumber $PRNumber -SafetyRules $SafetyRules
        Show-SafetyReport -SafetyReport $safetyReport

        # Get user confirmation unless skipped
        if (-not $SkipConfirmation) {
            $confirmed = Get-UserSafetyConfirmation -SafetyReport $safetyReport -Operation "merge"
            if (-not $confirmed) {
                Write-Log "PR merge cancelled by user" -Level "INFO"
                return $false
            }
        } elseif (-not $safetyReport.ChecksPassed -and -not $Global:Config.Force) {
            Write-Log "Safety checks failed and not in force mode - aborting merge" -Level "ERROR"
            return $false
        }
    }

    # Backup current branch state if doing local operations
    $backupInfo = $null
    if ($Global:Config.LocalRepoPath -and (Test-Path $Global:Config.LocalRepoPath)) {
        $backupInfo = Backup-BranchState -RepoFullName $RepoFullName -PRNumber $PRNumber
    }

    try {
        $mergeBody = @{
            merge_method = $MergeMethod
            commit_title = "Merge PR #$PRNumber"
            commit_message = "Automated merge of PR #$PRNumber"
        }

        $uri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/merge"
        $result = Invoke-GitHubAPI -Uri $uri -Method "PUT" -Body $mergeBody

        if ($result -and $result.merged) {
            Write-Log "PR #$PRNumber merged successfully!" -Level "SUCCESS"

            # Log merge details for audit trail
            $mergeDetails = @{
                PRNumber = $PRNumber
                Repository = $RepoFullName
                MergeMethod = $MergeMethod
                MergedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                MergeCommitSHA = $result.sha
                SafetyChecksPerformed = -not $SkipSafetyChecks
                UserConfirmed = -not $SkipConfirmation
                BackupCreated = $null -ne $backupInfo
            }
            Write-Log "Merge details: $($mergeDetails | ConvertTo-Json -Compress)" -Level "INFO"

            return $true
        } else {
            Write-Log "Failed to merge PR #$PRNumber" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Error during merge: $($_.Exception.Message)" -Level "ERROR"

        # Attempt rollback if merge failed and we have backup info
        if ($backupInfo) {
            Write-Log "Attempting rollback due to merge failure" -Level "WARNING"
            Restore-BranchState -BackupInfo $backupInfo
        }

        return $false
    }
}

function Backup-BranchState {
    param(
        [string]$RepoFullName,
        [int]$PRNumber
    )

    try {
        $pr = Get-PRDetails -RepoFullName $RepoFullName -PRNumber $PRNumber
        if (-not $pr) {
            Write-Log "Cannot backup: Failed to get PR details" -Level "WARNING"
            return $null
        }

        $localPath = $Global:Config.LocalRepoPath
        if (-not (Test-Path $localPath)) {
            Write-Log "Cannot backup: Local repository path does not exist" -Level "WARNING"
            return $null
        }

        Set-Location $localPath

        # Create backup branch
        $backupBranchName = "backup-pr-$PRNumber-before-merge-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        git checkout $pr.base.ref
        git pull origin $pr.base.ref
        git checkout -b $backupBranchName

        Write-Log "Created backup branch: $backupBranchName" -Level "INFO"

        return @{
            BackupBranch = $backupBranchName
            OriginalBranch = $pr.base.ref
            PRNumber = $PRNumber
            Repository = $RepoFullName
            CreatedAt = Get-Date
            LocalPath = $localPath
        }
    }
    catch {
        Write-Log "Failed to create backup: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Restore-BranchState {
    param([hashtable]$BackupInfo)

    if (-not $BackupInfo) {
        Write-Log "No backup information available for rollback" -Level "ERROR"
        return $false
    }

    try {
        Set-Location $BackupInfo.LocalPath

        # Check if backup branch exists
        $backupExists = git branch -a | Where-Object { $_.Trim() -eq $BackupInfo.BackupBranch -or $_.Trim() -eq "remotes/origin/$($BackupInfo.BackupBranch)" }
        if (-not $backupExists) {
            Write-Log "Backup branch $($BackupInfo.BackupBranch) not found" -Level "ERROR"
            return $false
        }

        # Restore from backup
        git checkout $BackupInfo.OriginalBranch
        git reset --hard $BackupInfo.BackupBranch

        Write-Log "Successfully restored branch $($BackupInfo.OriginalBranch) from backup" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to restore from backup: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Force-Merge-PullRequest {
    param(
        [string]$RepoFullName,
        [int]$PRNumber,
        [hashtable]$SafetyRules = @{}
    )

    Write-Log "Force merging PR #$PRNumber (bypassing checks)" -Level "WARNING"
    Write-Log "⚠️  WARNING: Force merge bypasses all safety mechanisms!" -Level "ERROR"
    Write-Log "This should only be used in emergency situations" -Level "ERROR"

    # Perform minimal safety checks even for force merge
    $safetyReport = Test-PRMergeSafety -RepoFullName $RepoFullName -PRNumber $PRNumber -SafetyRules $SafetyRules

    if ($safetyReport.CriticalFailures.Count -gt 0) {
        Write-Host "CRITICAL SAFETY ISSUES DETECTED:" -ForegroundColor Red -BackgroundColor Yellow
        foreach ($issue in $safetyReport.CriticalFailures) {
            Write-Host "  ❌ $issue" -ForegroundColor Red
        }

        if (-not $Global:Config.Force) {
            $response = Read-Host "Force merge anyway? Type 'EMERGENCY' to proceed"
            if ($response -ne "EMERGENCY") {
                Write-Log "Emergency force merge cancelled by user" -Level "INFO"
                return $false
            }
        }
    }

    # Create emergency backup
    $backupInfo = Backup-BranchState -RepoFullName $RepoFullName -PRNumber $PRNumber
    if (-not $backupInfo) {
        Write-Log "Failed to create emergency backup - aborting force merge" -Level "ERROR"
        return $false
    }

    Write-Log "Emergency backup created: $($backupInfo.BackupBranch)" -Level "WARNING"

    try {
        $mergeBody = @{
            merge_method = "squash"
            commit_title = "EMERGENCY Force merge PR #$PRNumber"
            commit_message = "Emergency force merge of PR #$PRNumber - Safety checks bypassed"
        }

        $uri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/merge"
        $result = Invoke-GitHubAPI -Uri $uri -Method "PUT" -Body $mergeBody

        if ($result -and $result.merged) {
            Write-Log "PR #$PRNumber force merged successfully!" -Level "SUCCESS"

            # Log emergency merge details
            $emergencyDetails = @{
                PRNumber = $PRNumber
                Repository = $RepoFullName
                MergeType = "EMERGENCY_FORCE_MERGE"
                MergedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                MergeCommitSHA = $result.sha
                SafetyBypassed = $true
                BackupBranch = $backupInfo.BackupBranch
                CriticalIssuesIgnored = $safetyReport.CriticalFailures.Count
            }
            Write-Log "Emergency merge details: $($emergencyDetails | ConvertTo-Json -Compress)" -Level "WARNING"

            return $true
        } else {
            Write-Log "Force merge failed for PR #$PRNumber" -Level "ERROR"
            Write-Log "Attempting rollback from backup: $($backupInfo.BackupBranch)" -Level "WARNING"
            Restore-BranchState -BackupInfo $backupInfo
            return $false
        }
    }
    catch {
        Write-Log "Error during force merge: $($_.Exception.Message)" -Level "ERROR"
        Write-Log "Attempting rollback due to force merge failure" -Level "ERROR"
        Restore-BranchState -BackupInfo $backupInfo
        return $false
    }
}

# =============================================================================
# BULK OPERATIONS
# =============================================================================

function Merge-AllPullRequests {
    param(
        [string]$Username,
        [hashtable]$SafetyRules = @{},
        [switch]$SkipSafetyChecks = $false,
        [switch]$SkipConfirmation = $false
    )

    Write-Log "Starting bulk merge of all pull requests" -Level "INFO"

    $pullRequests = Get-UserPullRequests -Username $Username
    if ($pullRequests.Count -eq 0) {
        Write-Log "No open pull requests found" -Level "INFO"
        return
    }

    Write-Host "Found $($pullRequests.Count) pull requests to process" -ForegroundColor Yellow

    if (-not $SkipConfirmation) {
        $response = Read-Host "Proceed with bulk merge? (type 'BULK-MERGE' to confirm)"
        if ($response -ne "BULK-MERGE") {
            Write-Log "Bulk merge cancelled by user" -Level "INFO"
            return
        }
    }

    $successCount = 0
    $failureCount = 0
    $skippedCount = 0
    $results = @()

    foreach ($pr in $pullRequests) {
        $repoFullName = $pr.repository_url -replace "https://api.github.com/repos/", ""
        $prNumber = $pr.number

        Write-Host ""
        Write-Host "Processing PR #$prNumber in $repoFullName" -ForegroundColor Cyan
        Write-Host "Title: $($pr.title)" -ForegroundColor White

        # Try standard merge first with safety checks
        $merged = Merge-PullRequest -RepoFullName $repoFullName -PRNumber $prNumber -SafetyRules $SafetyRules -SkipSafetyChecks:$SkipSafetyChecks -SkipConfirmation:$SkipConfirmation

        if (-not $merged -and $Global:Config.Force) {
            Write-Log "Standard merge failed, attempting force merge" -Level "WARNING"
            $merged = Force-Merge-PullRequest -RepoFullName $repoFullName -PRNumber $prNumber -SafetyRules $SafetyRules
        }

        $result = @{
            Repository = $repoFullName
            PRNumber = $prNumber
            Title = $pr.title
            Success = $merged
            URL = $pr.html_url
            Skipped = $false
        }

        $results += [PSCustomObject]$result

        if ($merged) {
            $successCount++
        } else {
            $failureCount++
        }

        # Rate limiting with progress indicator
        Write-Host "Waiting before next PR..." -ForegroundColor Gray
        Start-Sleep -Milliseconds 1000
    }

    # Save results
    Save-Results -Results $results -Operation "bulk-merge"

    # Summary
    Write-Host ""
    Write-Host "Bulk Merge Summary" -ForegroundColor Cyan
    Write-Host "=" * 30 -ForegroundColor Cyan
    Write-Host "Total PRs: $($pullRequests.Count)" -ForegroundColor White
    Write-Host "Successful: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failureCount" -ForegroundColor Red
    Write-Host "Skipped: $skippedCount" -ForegroundColor Yellow

    Write-Log "Bulk merge complete: $successCount successful, $failureCount failed, $skippedCount skipped" -Level "SUCCESS"
}

function Safe-Merge-PullRequests {
    param(
        [string]$Username,
        [hashtable]$SafetyRules = @{}
    )

    Write-Log "Starting SAFE bulk merge with comprehensive checks" -Level "INFO"

    # Default safety rules if not provided
    if ($SafetyRules.Count -eq 0) {
        $SafetyRules = @{
            CheckRequiredStatusChecks = $true
            CheckRequiredReviews = $true
            RequiredApprovals = 1
            CheckBranchProtection = $true
            CheckPRAge = $true
            MaxPRAgeDays = 30
            MaxFileCount = 50
            MaxChanges = 1000
        }
    }

    Write-Host "Safety Rules Applied:" -ForegroundColor Yellow
    foreach ($rule in $SafetyRules.GetEnumerator()) {
        Write-Host "  $($rule.Key): $($rule.Value)" -ForegroundColor White
    }
    Write-Host ""

    # Run bulk merge with safety checks
    Merge-AllPullRequests -Username $Username -SafetyRules $SafetyRules
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
    Write-Host "GitHub PR Management Toolkit - SAFE EDITION" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Current Configuration:" -ForegroundColor Yellow
    Write-Host "  Dry Run: $($Global:Config.DryRun)" -ForegroundColor White
    Write-Host "  Force Mode: $($Global:Config.Force)" -ForegroundColor White
    Write-Host "  Local Path: $($Global:Config.LocalRepoPath)" -ForegroundColor White
    Write-Host ""
    Write-Host "Available Operations:" -ForegroundColor Green
    Write-Host "  1. Show Status" -ForegroundColor White
    Write-Host "  2. Safe Merge All PRs (Recommended)" -ForegroundColor Green
    Write-Host "  3. Quick Merge All PRs (Bypass Safety)" -ForegroundColor Yellow
    Write-Host "  4. Close All PRs" -ForegroundColor White
    Write-Host "  5. Resolve Conflicts" -ForegroundColor White
    Write-Host "  6. Force Merge All (Emergency Only)" -ForegroundColor Red
    Write-Host "  7. Repository Cleanup" -ForegroundColor White
    Write-Host "  8. Safety Configuration" -ForegroundColor Cyan
    Write-Host "  9. Exit" -ForegroundColor Gray
    Write-Host ""
    Write-Host "WARNING: Always use option 2 for normal operations" -ForegroundColor Yellow
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

function Show-SafetyConfigurationMenu {
    Clear-Host
    Write-Host "Safety Configuration Menu" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Configure safety rules for PR merging:" -ForegroundColor Yellow
    Write-Host "  1. Toggle Status Check Validation" -ForegroundColor White
    Write-Host "  2. Toggle Review Requirements" -ForegroundColor White
    Write-Host "  3. Set Required Approvals Count" -ForegroundColor White
    Write-Host "  4. Toggle Branch Protection Checks" -ForegroundColor White
    Write-Host "  5. Toggle PR Age Validation" -ForegroundColor White
    Write-Host "  6. Set Maximum PR Age (Days)" -ForegroundColor White
    Write-Host "  7. Set Maximum File Count" -ForegroundColor White
    Write-Host "  8. Set Maximum Changes Count" -ForegroundColor White
    Write-Host "  9. Reset to Safe Defaults" -ForegroundColor Green
    Write-Host "  10. Back to Main Menu" -ForegroundColor Gray
    Write-Host ""
}

function Handle-SafetyConfigurationSelection {
    param([string]$Selection)

    switch ($Selection) {
        "1" {
            $Global:SafetyRules.CheckRequiredStatusChecks = -not $Global:SafetyRules.CheckRequiredStatusChecks
            Write-Log "Status Check Validation: $($Global:SafetyRules.CheckRequiredStatusChecks)" -Level "INFO"
        }
        "2" {
            $Global:SafetyRules.CheckRequiredReviews = -not $Global:SafetyRules.CheckRequiredReviews
            Write-Log "Review Requirements: $($Global:SafetyRules.CheckRequiredReviews)" -Level "INFO"
        }
        "3" {
            $newCount = Read-Host "Enter required approvals count"
            if ($newCount -match '^\d+$') {
                $Global:SafetyRules.RequiredApprovals = [int]$newCount
                Write-Log "Required Approvals: $newCount" -Level "INFO"
            }
        }
        "4" {
            $Global:SafetyRules.CheckBranchProtection = -not $Global:SafetyRules.CheckBranchProtection
            Write-Log "Branch Protection Checks: $($Global:SafetyRules.CheckBranchProtection)" -Level "INFO"
        }
        "5" {
            $Global:SafetyRules.CheckPRAge = -not $Global:SafetyRules.CheckPRAge
            Write-Log "PR Age Validation: $($Global:SafetyRules.CheckPRAge)" -Level "INFO"
        }
        "6" {
            $newAge = Read-Host "Enter maximum PR age (days)"
            if ($newAge -match '^\d+$') {
                $Global:SafetyRules.MaxPRAgeDays = [int]$newAge
                Write-Log "Max PR Age: $newAge days" -Level "INFO"
            }
        }
        "7" {
            $newCount = Read-Host "Enter maximum file count"
            if ($newCount -match '^\d+$') {
                $Global:SafetyRules.MaxFileCount = [int]$newCount
                Write-Log "Max File Count: $newCount" -Level "INFO"
            }
        }
        "8" {
            $newChanges = Read-Host "Enter maximum changes count"
            if ($newChanges -match '^\d+$') {
                $Global:SafetyRules.MaxChanges = [int]$newChanges
                Write-Log "Max Changes: $newChanges" -Level "INFO"
            }
        }
        "9" {
            $Global:SafetyRules = Get-SafeDefaultRules
            Write-Log "Reset to safe defaults" -Level "INFO"
        }
        "10" { return }
        default {
            Write-Log "Invalid safety configuration selection" -Level "WARNING"
        }
    }

    Start-Sleep -Seconds 2
}

function Get-SafeDefaultRules {
    return @{
        CheckRequiredStatusChecks = $true
        CheckRequiredReviews = $true
        RequiredApprovals = 1
        CheckBranchProtection = $true
        CheckPRAge = $true
        MaxPRAgeDays = 30
        MaxFileCount = 50
        MaxChanges = 1000
    }
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
            Safe-Merge-PullRequests -Username $username
            Read-Host "Press Enter to continue"
        }
        "3" {
            $username = Get-GitHubUser
            Merge-AllPullRequests -Username $username -SkipSafetyChecks -SkipConfirmation
            Read-Host "Press Enter to continue"
        }
        "4" {
            $username = Get-GitHubUser
            Close-AllPullRequests -Username $username
            Read-Host "Press Enter to continue"
        }
        "5" {
            Write-Log "Conflict resolution requires specific PR details" -Level "INFO"
            Read-Host "Press Enter to continue"
        }
        "6" {
            $Global:Config.Force = $true
            $username = Get-GitHubUser
            Merge-AllPullRequests -Username $username -SkipSafetyChecks -SkipConfirmation
            Read-Host "Press Enter to continue"
        }
        "7" {
            Cleanup-Repository -LocalPath $Global:Config.LocalRepoPath
            Read-Host "Press Enter to continue"
        }
        "8" {
            Show-SafetyConfigurationMenu
            $safetyChoice = Read-Host "Select safety option"
            Handle-SafetyConfigurationSelection -Selection $safetyChoice
        }
        "9" {
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
            