# Maximum Code Preservation PR Merger
# This script merges PRs while preserving the maximum amount of code possible

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken
)

# Set up headers for GitHub API
$headers = @{
    'Authorization' = "token $GitHubToken"
    'Accept' = 'application/vnd.github.v3+json'
    'User-Agent' = 'PowerShell-Max-Code-Preserve-Merger'
}

# Function to make GitHub API calls
function Invoke-GitHubAPI {
    param([string]$Uri, [string]$Method = 'GET', [hashtable]$Body = @{})

    try {
        $params = @{
            Uri = $Uri
            Method = $Method
            Headers = $headers
            ContentType = 'application/json'
        }

        if ($Body.Count -gt 0) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }

        return Invoke-RestMethod @params
    }
    catch {
        Write-Warning "API call failed for $Uri : $($_.Exception.Message)"
        return $null
    }
}

# Function to get user information
function Get-GitHubUser {
    Write-Host "Getting user information..." -ForegroundColor Cyan
    $user = Invoke-GitHubAPI -Uri "https://api.github.com/user"
    if ($user) {
        Write-Host "Authenticated as: $($user.login)" -ForegroundColor Green
        return $user.login
    } else {
        Write-Error "Failed to authenticate with GitHub"
        exit 1
    }
}

# Function to get all open pull requests
function Get-UserPullRequests {
    param([string]$Username)

    Write-Host "Fetching all open pull requests..." -ForegroundColor Cyan

    $searchQuery = "is:pr is:open author:$Username"
    $uri = "https://api.github.com/search/issues?q=" + [System.Web.HttpUtility]::UrlEncode($searchQuery) + "&per_page=100"

    $allPRs = @()
    $page = 1

    do {
        $currentUri = "$uri&page=$page"
        $response = Invoke-GitHubAPI -Uri $currentUri

        if ($response -and $response.items) {
            $allPRs += $response.items
            Write-Host "Found $($response.items.Count) PRs on page $page" -ForegroundColor Yellow
            $page++
        } else {
            break
        }
    } while ($response.items.Count -eq 100)

    Write-Host "Total open PRs found: $($allPRs.Count)" -ForegroundColor Green
    return $allPRs
}

# Function to preserve maximum code during merge conflicts
function Preserve-Maximum-Code {
    param([string]$RepoFullName, [int]$PRNumber)

    Write-Host "[WORKING] PRESERVING MAXIMUM CODE for PR #$PRNumber" -ForegroundColor Magenta

    # Get PR details
    $prDetailUri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber"
    $pr = Invoke-GitHubAPI -Uri $prDetailUri

    if (-not $pr) {
        return @{ success = $false; message = "Failed to get PR details" }
    }

    # Try different merge strategies in order of code preservation
    $mergeMethods = @('merge', 'squash', 'rebase')

    foreach ($method in $mergeMethods) {
        Write-Host "  Trying $method merge..." -ForegroundColor Yellow

        $mergeBody = @{
            commit_title = "Maximum Code Preservation: Merge PR #$PRNumber"
            commit_message = "Auto-merged PR #$PRNumber preserving maximum code"
            merge_method = $method
        }

        $mergeUri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/merge"
        $mergeResult = Invoke-GitHubAPI -Uri $mergeUri -Method "PUT" -Body $mergeBody

        if ($mergeResult -and $mergeResult.merged) {
            Write-Host "  [SUCCESS] $method merge successful!" -ForegroundColor Green
            return @{ success = $true; message = "$method merge completed"; method = $method }
        } else {
            $errorMsg = if ($mergeResult) { $mergeResult.message } else { "Unknown error" }
            Write-Host "  [FAILED] $method merge failed: $errorMsg" -ForegroundColor Red
        }
    }

    return @{ success = $false; message = "All merge methods failed" }
}

# Main execution
function Main {
    Write-Host "[TOOL] MAXIMUM CODE PRESERVATION PR MERGER" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan

    # Get user info
    $username = Get-GitHubUser

    # Get all open PRs
    $pullRequests = Get-UserPullRequests -Username $username

    if ($pullRequests.Count -eq 0) {
        Write-Host "✅ No open pull requests found!" -ForegroundColor Green
        return
    }

    # Initialize counters
    $successCount = 0
    $failureCount = 0
    $results = @()

    # Process each PR
    foreach ($pr in $pullRequests) {
        $repoFullName = $pr.repository_url -replace "https://api.github.com/repos/", ""
        $prNumber = $pr.number

        Write-Host "`n--- Processing PR #$prNumber in $repoFullName ---" -ForegroundColor Magenta
        Write-Host "Title: $($pr.title)" -ForegroundColor White
        Write-Host "URL: $($pr.html_url)" -ForegroundColor Blue

        $result = Preserve-Maximum-Code -RepoFullName $repoFullName -PRNumber $prNumber

        $results += [PSCustomObject]@{
            Repository = $repoFullName
            PRNumber = $prNumber
            Title = $pr.title
            Success = $result.success
            Message = $result.message
            Method = if ($result.method) { $result.method } else { "N/A" }
            URL = $pr.html_url
        }

        if ($result.success) {
            $successCount++
        } else {
            $failureCount++
        }

        # Rate limiting
        Start-Sleep -Milliseconds 1000
    }

    # Summary report
    Write-Host "`n==================================================" -ForegroundColor Cyan
    Write-Host "MAXIMUM CODE PRESERVATION MERGE SUMMARY" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "Total PRs processed: $($pullRequests.Count)" -ForegroundColor White
    Write-Host "Successful merges: $successCount" -ForegroundColor Green
    Write-Host "Failed merges: $failureCount" -ForegroundColor Red

    Write-Host "`nDetailed Results:" -ForegroundColor Yellow
    $results | Format-Table -AutoSize

    # Save results to file
    $resultFile = "max-code-preservation-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFile
    Write-Host "`n[RESULTS] Results saved to: $resultFile" -ForegroundColor Cyan
}

# Run the main function
Main
