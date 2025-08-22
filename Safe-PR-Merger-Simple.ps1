# 🔒 Safe PR Merger - Simplified Edition
# GitHub PR Management with Essential Safety Features

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,

    [Parameter(Mandatory=$false)]
    [string]$Operation = "menu"
)

# Global Configuration
$Global:Config = @{
    GitHubToken = $GitHubToken
    DryRun = $DryRun
    ResultsPath = ".\Results"
    LogPath = ".\Logs"
}

# GitHub API Headers
$Global:Headers = @{
    'Authorization' = "token $GitHubToken"
    'Accept' = 'application/vnd.github.v3+json'
    'User-Agent' = 'PowerShell-Safe-PR-Merger'
}

# Safety Rules
$Global:SafetyRules = @{
    CheckRequiredStatusChecks = $true
    CheckRequiredReviews = $true
    RequiredApprovals = 1
    CheckBranchProtection = $true
    MaxFileCount = 50
    MaxChanges = 1000
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO", [string]$Color = "White")

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
    $logFile = Join-Path $Global:Config.LogPath "safe-merger-$(Get-Date -Format 'yyyyMMdd').log"
    if (-not (Test-Path $Global:Config.LogPath)) {
        New-Item -ItemType Directory -Path $Global:Config.LogPath -Force | Out-Null
    }
    $logMessage | Out-File -FilePath $logFile -Append
}

function Invoke-GitHubAPI {
    param([string]$Uri, [string]$Method = 'GET', [hashtable]$Body = @{})

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
# SAFETY FUNCTIONS
# =============================================================================

function Test-PRMergeSafety {
    param([string]$RepoFullName, [int]$PRNumber)

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
    if ($Global:SafetyRules.CheckRequiredStatusChecks -and $pr.head.sha) {
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
    if ($Global:SafetyRules.CheckRequiredReviews) {
        $reviewsUri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/reviews"
        $reviews = Invoke-GitHubAPI -Uri $reviewsUri

        $approvedReviews = ($reviews | Where-Object { $_.state -eq "APPROVED" }).Count
        $requiredApprovals = $Global:SafetyRules.RequiredApprovals

        if ($approvedReviews -lt $requiredApprovals) {
            $safetyReport.ChecksPassed = $false
            $safetyReport.CriticalFailures += "Insufficient approvals: $approvedReviews/$requiredApprovals required"
        }
    }

    # Check 4: PR size and complexity
    $files = Get-PRFiles -RepoFullName $RepoFullName -PRNumber $PRNumber
    if ($files) {
        $totalAdditions = ($files | Measure-Object -Property additions -Sum).Sum
        $totalDeletions = ($files | Measure-Object -Property deletions -Sum).Sum
        $fileCount = $files.Count

        if ($Global:SafetyRules.MaxFileCount -and $fileCount -gt $Global:SafetyRules.MaxFileCount) {
            $safetyReport.Warnings += "Large PR: $fileCount files (max recommended: $($Global:SafetyRules.MaxFileCount))"
        }

        if ($Global:SafetyRules.MaxChanges -and ($totalAdditions + $totalDeletions) -gt $Global:SafetyRules.MaxChanges) {
            $safetyReport.Warnings += "Large PR: $($totalAdditions + $totalDeletions) changes (max recommended: $($Global:SafetyRules.MaxChanges))"
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

    if ($SafetyReport.ChecksPassed -and $SafetyReport.CriticalFailures.Count -eq 0) {
        Write-Host "All safety checks passed!" -ForegroundColor Green
    } else {
        Write-Host "Safety checks failed - merge not recommended" -ForegroundColor Red
    }

    Write-Host ""
}

function Get-UserSafetyConfirmation {
    param([hashtable]$SafetyReport, [string]$Operation)

    Write-Host "Safety Confirmation Required" -ForegroundColor Yellow
    Write-Host "=" * 30 -ForegroundColor Yellow

    if (-not $SafetyReport.ChecksPassed) {
        Write-Host "Warning: Some safety checks failed!" -ForegroundColor Red
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
# MERGE FUNCTIONS
# =============================================================================

function Merge-PullRequest {
    param([string]$RepoFullName, [int]$PRNumber, [string]$MergeMethod = "merge")

    Write-Log "Merging PR #$PRNumber using method: $MergeMethod" -Level "INFO"

    # Perform safety checks
    $safetyReport = Test-PRMergeSafety -RepoFullName $RepoFullName -PRNumber $PRNumber
    Show-SafetyReport -SafetyReport $safetyReport

    # Get user confirmation
    if (-not $Global:Config.DryRun) {
        $confirmed = Get-UserSafetyConfirmation -SafetyReport $safetyReport -Operation "merge"
        if (-not $confirmed) {
            Write-Log "PR merge cancelled by user" -Level "INFO"
            return $false
        }
    } elseif (-not $safetyReport.ChecksPassed) {
        Write-Log "Safety checks failed - aborting merge" -Level "ERROR"
        return $false
    }

    if ($Global:Config.DryRun) {
        Write-Log "DRY RUN: Would merge PR #$PRNumber" -Level "INFO"
        return $true
    }

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

function Safe-Merge-PullRequests {
    param([string]$Username)

    Write-Log "Starting SAFE bulk merge with comprehensive checks" -Level "INFO"

    $pullRequests = Get-UserPullRequests -Username $Username
    if ($pullRequests.Count -eq 0) {
        Write-Log "No open pull requests found" -Level "INFO"
        return
    }

    Write-Host "Found $($pullRequests.Count) pull requests to process" -ForegroundColor Yellow

    if (-not $Global:Config.DryRun) {
        $response = Read-Host "Proceed with bulk merge? (type 'BULK-MERGE' to confirm)"
        if ($response -ne "BULK-MERGE") {
            Write-Log "Bulk merge cancelled by user" -Level "INFO"
            return
        }
    }

    $successCount = 0
    $failureCount = 0
    $results = @()

    foreach ($pr in $pullRequests) {
        $repoFullName = $pr.repository_url -replace "https://api.github.com/repos/", ""
        $prNumber = $pr.number

        Write-Host ""
        Write-Host "Processing PR #$prNumber in $repoFullName" -ForegroundColor Cyan
        Write-Host "Title: $($pr.title)" -ForegroundColor White

        $merged = Merge-PullRequest -RepoFullName $repoFullName -PRNumber $prNumber

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

        Write-Host "Waiting before next PR..." -ForegroundColor Gray
        Start-Sleep -Milliseconds 1000
    }

    Write-Host ""
    Write-Host "Bulk Merge Summary" -ForegroundColor Cyan
    Write-Host "=" * 30 -ForegroundColor Cyan
    Write-Host "Total PRs: $($pullRequests.Count)" -ForegroundColor White
    Write-Host "Successful: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failureCount" -ForegroundColor Red

    Write-Log "Bulk merge complete: $successCount successful, $failureCount failed" -Level "SUCCESS"
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
# MAIN MENU
# =============================================================================

function Show-MainMenu {
    Clear-Host
    Write-Host "Safe PR Merger - Essential Edition" -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Current Configuration:" -ForegroundColor Yellow
    Write-Host "  Dry Run: $($Global:Config.DryRun)" -ForegroundColor White
    Write-Host ""
    Write-Host "Available Operations:" -ForegroundColor Green
    Write-Host "  1. Show Status" -ForegroundColor White
    Write-Host "  2. Safe Merge All PRs (Recommended)" -ForegroundColor Green
    Write-Host "  3. Exit" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Safety: Always use option 2 for normal operations" -ForegroundColor Yellow
}

function Main {
    Write-Log "Safe PR Merger starting..." -Level "INFO"

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
            "merge" { Safe-Merge-PullRequests -Username $username }
            default { Write-Log "Unknown operation: $Operation" -Level "ERROR" }
        }
    } else {
        # Interactive menu mode
        do {
            Show-MainMenu
            $choice = Read-Host "Select operation"
            switch ($choice) {
                "1" { Show-Status -Username $username; Read-Host "Press Enter to continue" }
                "2" { Safe-Merge-PullRequests -Username $username; Read-Host "Press Enter to continue" }
                "3" { Write-Log "Exiting Safe PR Merger" -Level "INFO"; exit 0 }
                default { Write-Log "Invalid selection" -Level "WARNING"; Start-Sleep -Seconds 1 }
            }
        } while ($true)
    }
}

# Start the Safe PR Merger
Main
