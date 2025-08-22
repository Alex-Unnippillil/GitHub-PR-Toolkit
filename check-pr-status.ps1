# Check actual PR status to see if they're really merged
param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken
)

# Set up headers for GitHub API
$headers = @{
    'Authorization' = "token $GitHubToken"
    'Accept' = 'application/vnd.github.v3+json'
    'User-Agent' = 'PowerShell-PR-Status-Checker'
}

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

function Get-GitHubUser {
    Write-Host "Getting user information..." -ForegroundColor Cyan
    $user = Invoke-GitHubAPI -Uri "https://api.github.com/user"
    if ($user) {
        Write-Host "Authenticated as: $($user.login)" -ForegroundColor Green
        return $user.login
    } else {
        Write-Error "Failed to authenticate"
        exit 1
    }
}

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

function Main {
    Write-Host "=== PR STATUS CHECKER ===" -ForegroundColor Cyan
    Write-Host "Checking if PRs are actually merged..." -ForegroundColor White

    $username = Get-GitHubUser
    $pullRequests = Get-UserPullRequests -Username $username

    if ($pullRequests.Count -eq 0) {
        Write-Host "No open pull requests found!" -ForegroundColor Green
        return
    }

    Write-Host "`n=== DETAILED PR ANALYSIS ===" -ForegroundColor Magenta

    foreach ($pr in $pullRequests) {
        $repoFullName = $pr.repository_url -replace "https://api.github.com/repos/", ""
        $prNumber = $pr.number

        Write-Host "`n--- PR #$prNumber ---" -ForegroundColor Yellow
        Write-Host "Repository: $repoFullName" -ForegroundColor White
        Write-Host "Title: $($pr.title)" -ForegroundColor White
        Write-Host "State: $($pr.state)" -ForegroundColor White
        Write-Host "URL: $($pr.html_url)" -ForegroundColor Blue

        # Get detailed PR info
        $prDetailUri = "https://api.github.com/repos/$repoFullName/pulls/$prNumber"
        $prDetail = Invoke-GitHubAPI -Uri $prDetailUri

        if ($prDetail) {
            Write-Host "Mergeable: $($prDetail.mergeable)" -ForegroundColor Cyan
            Write-Host "Mergeable State: $($prDetail.mergeable_state)" -ForegroundColor Cyan
            Write-Host "Merged: $($prDetail.merged)" -ForegroundColor Cyan

            if ($prDetail.merged_by) {
                Write-Host "Merged By: $($prDetail.merged_by.login)" -ForegroundColor Green
                Write-Host "Merged At: $($prDetail.merged_at)" -ForegroundColor Green
            }

            if ($prDetail.mergeable -eq $false) {
                Write-Host "Merge Conflicts: YES" -ForegroundColor Red
                Write-Host "Conflict Details: $($prDetail.mergeable_state)" -ForegroundColor Red
            } else {
                Write-Host "Merge Conflicts: NO" -ForegroundColor Green
            }
        } else {
            Write-Host "Could not get PR details" -ForegroundColor Red
        }

        Start-Sleep -Milliseconds 500
    }

    Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Total PRs Checked: $($pullRequests.Count)" -ForegroundColor White
    Write-Host "Open PRs: $($pullRequests.Count)" -ForegroundColor Yellow
}

Main
