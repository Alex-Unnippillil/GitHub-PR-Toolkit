# 🚀 Auto Force Merge All Open PRs
# Automatically force merges all open pull requests without prompts

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken
)

# GitHub API headers
$Headers = @{
    'Authorization' = "token $GitHubToken"
    'Accept' = 'application/vnd.github.v3+json'
    'User-Agent' = 'PowerShell-Auto-Force-Merge'
}

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Invoke-GitHubAPI {
    param([string]$Uri, [string]$Method = 'GET', [hashtable]$Body = @{})
    
    try {
        $params = @{
            Uri = $Uri
            Method = $Method
            Headers = $Headers
            ContentType = 'application/json'
        }
        
        if ($Body.Count -gt 0) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $result = Invoke-RestMethod @params
        return $result
    }
    catch {
        Write-Log "API call failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-UserPullRequests {
    param([string]$Username)
    
    Write-Log "Fetching all open pull requests..." -ForegroundColor Cyan
    
    $searchQuery = "is:pr is:open author:$Username"
    $uri = "https://api.github.com/search/issues?q=" + [System.Web.HttpUtility]::UrlEncode($searchQuery) + "&per_page=100"
    
    $allPRs = @()
    $page = 1
    
    do {
        $currentUri = "$uri&page=$page"
        $response = Invoke-GitHubAPI -Uri $currentUri
        
        if ($response -and $response.items) {
            $allPRs += $response.items
            Write-Log "Found $($response.items.Count) PRs on page $page" -ForegroundColor Green
            $page++
        } else {
            break
        }
    } while ($response.items.Count -eq 100)
    
    Write-Log "Total open PRs found: $($allPRs.Count)" -ForegroundColor Green
    return $allPRs
}

function Force-Merge-PR {
    param([string]$RepoFullName, [int]$PRNumber, [string]$Title)
    
    Write-Log "Force merging PR #$PRNumber - $Title" -ForegroundColor Yellow
    
    try {
        $mergeBody = @{
            merge_method = "squash"
            commit_title = "Auto Force Merge PR #$PRNumber"
            commit_message = "Automated force merge of PR #$PRNumber - $Title"
        }

        $uri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/merge"
        $result = Invoke-GitHubAPI -Uri $uri -Method "PUT" -Body $mergeBody

        if ($result -and $result.merged) {
            Write-Log "Successfully force merged PR #$PRNumber" -ForegroundColor Green
            return $true
        } else {
            Write-Log "Failed to force merge PR #$PRNumber" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Log "Error force merging PR #$PRNumber - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Log "🚀 Starting Auto Force Merge of All Open PRs" -ForegroundColor Cyan
Write-Log "⚠️  WARNING: This will force merge ALL open PRs without safety checks!" -ForegroundColor Red

# Get user info
$user = Invoke-GitHubAPI -Uri "https://api.github.com/user"
if (-not $user) {
    Write-Log "Failed to authenticate. Check your token." -ForegroundColor Red
    exit 1
}

Write-Log "Authenticated as: $($user.login)" -ForegroundColor Green

# Get all open PRs
$pullRequests = Get-UserPullRequests -Username $user.login

if ($pullRequests.Count -eq 0) {
    Write-Log "No open pull requests found." -ForegroundColor Yellow
    exit 0
}

Write-Log "Starting force merge of $($pullRequests.Count) PRs..." -ForegroundColor Cyan

$successCount = 0
$failureCount = 0
$results = @()

foreach ($pr in $pullRequests) {
    $repoFullName = $pr.repository_url -replace "https://api.github.com/repos/", ""
    $prNumber = $pr.number
    
    Write-Log "Processing PR #$prNumber in $repoFullName" -ForegroundColor White
    
    $merged = Force-Merge-PR -RepoFullName $repoFullName -PRNumber $prNumber -Title $pr.title
    
    $result = @{
        Repository = $repoFullName
        PRNumber = $prNumber
        Title = $pr.title
        Success = $merged
        URL = $pr.html_url
        ProcessedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $results += [PSCustomObject]$result
    
    if ($merged) {
        $successCount++
    } else {
        $failureCount++
    }
    
    # Rate limiting - wait 1 second between PRs
    Start-Sleep -Seconds 1
}

# Save results
$resultsPath = ".\Results"
if (-not (Test-Path $resultsPath)) {
    New-Item -ItemType Directory -Path $resultsPath -Force | Out-Null
}

$resultFile = Join-Path $resultsPath "auto-force-merge-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFile

# Summary
Write-Log "" -ForegroundColor White
Write-Log "🎯 Auto Force Merge Complete!" -ForegroundColor Cyan
Write-Log "=" * 40 -ForegroundColor Cyan
Write-Log "Total PRs processed: $($pullRequests.Count)" -ForegroundColor White
Write-Log "✅ Successful merges: $successCount" -ForegroundColor Green
Write-Log "❌ Failed merges: $failureCount" -ForegroundColor Red
Write-Log "Results saved to: $resultFile" -ForegroundColor Yellow

Write-Log "All done! 🚀" -ForegroundColor Green
