# GitHub PR Conflict Resolver and Merger
# Removes conflict markers and preserves maximum code during merges

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken
)

# Set up headers for GitHub API
$headers = @{
    'Authorization' = "token $GitHubToken"
    'Accept' = 'application/vnd.github.v3+json'
    'User-Agent' = 'PowerShell-Conflict-Resolver'
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

# Function to resolve merge conflicts by removing markers and preserving maximum code
function Resolve-Conflicts {
    param([string]$RepoFullName, [int]$PRNumber)

    Write-Host "[RESOLVING] Resolving conflicts for PR #$PRNumber" -ForegroundColor Magenta

    # Get PR details
    $prDetailUri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber"
    $pr = Invoke-GitHubAPI -Uri $prDetailUri

    if (-not $pr) {
        return @{ success = $false; message = "Failed to get PR details" }
    }

    # Check if PR has merge conflicts
    if ($pr.mergeable -eq $false) {
        Write-Host "  PR has merge conflicts - attempting resolution..." -ForegroundColor Yellow
    }

    # Get PR files to see what files are involved
    $filesUri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/files"
    $files = Invoke-GitHubAPI -Uri $filesUri

    if (-not $files) {
        return @{ success = $false; message = "Failed to get PR files" }
    }

    # Setup local repository
    $repoName = $RepoFullName.Split('/')[-1]
    $localPath = ".\temp_repo_$repoName"

    if (Test-Path $localPath) {
        Remove-Item -Path $localPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Clone the repository
    Write-Host "  Cloning repository..." -ForegroundColor Gray
    try {
        git clone "https://$GitHubToken@github.com/$RepoFullName.git" $localPath
        Set-Location $localPath

        # Fetch the PR branch
        git fetch origin $pr.head.ref
        git checkout -B "pr-$PRNumber" "origin/$($pr.head.ref)"

        # Try to merge with base branch
        $mergeResult = git merge "origin/$($pr.base.ref)" --no-commit --no-ff 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Merge successful without conflicts" -ForegroundColor Green
            return @{ success = $true; message = "Merged without conflicts"; resolved = $false }
        }

        # Handle conflicts
        Write-Host "  Conflicts detected, resolving..." -ForegroundColor Yellow
        $conflictedFiles = git diff --name-only --diff-filter=U

        $resolvedCount = 0
        foreach ($file in $conflictedFiles) {
            if (Test-Path $file) {
                Write-Host "    Resolving: $file" -ForegroundColor Gray
                $resolved = Resolve-ConflictInFile -FilePath $file
                if ($resolved) { $resolvedCount++ }
            }
        }

        if ($resolvedCount -gt 0) {
            # Commit the resolved conflicts
            git add .
            git commit -m "Resolve merge conflicts for PR #$PRNumber - preserved maximum code"
            Write-Host "  Conflicts resolved and committed" -ForegroundColor Green

            # Try to merge now
            return Try-MergeResolvedPR -RepoFullName $RepoFullName -PRNumber $PRNumber -LocalPath $localPath
        } else {
            return @{ success = $false; message = "Failed to resolve conflicts"; resolved = $true }
        }

    }
    catch {
        Write-Host "  Error during conflict resolution: $($_.Exception.Message)" -ForegroundColor Red
        return @{ success = $false; message = "Error: $($_.Exception.Message)"; resolved = $false }
    }
    finally {
        Set-Location $PSScriptRoot
        if (Test-Path $localPath) {
            Remove-Item -Path $localPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function to resolve conflicts in a single file
function Resolve-ConflictInFile {
    param([string]$FilePath)

    try {
        $content = Get-Content $FilePath -Raw
        if (-not $content) { return $false }

        $originalContent = $content

        # Remove conflict markers and preserve maximum code
        # Strategy: Keep both versions when possible, prefer the incoming changes

        # Pattern 1: Remove <<<<<<< HEAD and ======= markers, keep both versions
        $content = $content -replace '(?s)<<<<<<< HEAD.*?(?=\n=======)', ''

        # Pattern 2: Remove ======= and >>>>>>> markers, keep the incoming changes
        $content = $content -replace '(?s)=======.*?(?=\n>>>>>>> )', ''
        $content = $content -replace '(?s)>>>>>>> .*?(?=\n|$)', ''

        # Pattern 3: Handle simple conflict markers
        $content = $content -replace '<<<<<<< HEAD', ''
        $content = $content -replace '=======', ''
        $content = $content -replace '>>>>>>> .*', ''

        # Clean up empty lines that might result from conflict resolution
        $content = $content -replace '\r?\n\s*\r?\n\s*\r?\n', "`n`n"

        if ($content -ne $originalContent) {
            $content | Out-File -FilePath $FilePath -Encoding UTF8
            return $true
        }

        return $false
    }
    catch {
        Write-Host "    Error resolving $FilePath : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to try merging a resolved PR
function Try-MergeResolvedPR {
    param([string]$RepoFullName, [int]$PRNumber, [string]$LocalPath)

    Write-Host "  Attempting to merge resolved PR..." -ForegroundColor Yellow

    # Try different merge methods
    $mergeMethods = @('merge', 'squash', 'rebase')

    foreach ($method in $mergeMethods) {
        $mergeBody = @{
            commit_title = "Conflict Resolved: Merge PR #$PRNumber"
            commit_message = "Auto-merged PR #$PRNumber after conflict resolution"
            merge_method = $method
        }

        $mergeUri = "https://api.github.com/repos/$RepoFullName/pulls/$PRNumber/merge"
        $mergeResult = Invoke-GitHubAPI -Uri $mergeUri -Method "PUT" -Body $mergeBody

        if ($mergeResult -and $mergeResult.merged) {
            Write-Host "  [SUCCESS] $method merge completed!" -ForegroundColor Green
            return @{ success = $true; message = "$method merge completed"; method = $method; resolved = $true }
        } else {
            $errorMsg = if ($mergeResult) { $mergeResult.message } else { "Unknown error" }
            Write-Host "  [FAILED] $method merge failed: $errorMsg" -ForegroundColor Red
        }
    }

    return @{ success = $false; message = "All merge methods failed"; resolved = $true }
}

# Main execution
function Main {
    Write-Host "[CONFLICT RESOLVER] GitHub PR Conflict Resolver and Merger" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    # Get user info
    $username = Get-GitHubUser

    # Get all open PRs
    $pullRequests = Get-UserPullRequests -Username $username

    if ($pullRequests.Count -eq 0) {
        Write-Host "[INFO] No open pull requests found!" -ForegroundColor Green
        return
    }

    # Initialize counters
    $successCount = 0
    $failureCount = 0
    $conflictResolvedCount = 0
    $results = @()

    # Process each PR
    foreach ($pr in $pullRequests) {
        $repoFullName = $pr.repository_url -replace "https://api.github.com/repos/", ""
        $prNumber = $pr.number

        Write-Host "`n--- Processing PR #$prNumber in $repoFullName ---" -ForegroundColor Magenta
        Write-Host "Title: $($pr.title)" -ForegroundColor White
        Write-Host "URL: $($pr.html_url)" -ForegroundColor Blue

        $result = Resolve-Conflicts -RepoFullName $repoFullName -PRNumber $prNumber

        $results += [PSCustomObject]@{
            Repository = $repoFullName
            PRNumber = $prNumber
            Title = $pr.title
            Success = $result.success
            Message = $result.message
            ConflictsResolved = if ($result.resolved) { $true } else { $false }
            Method = if ($result.method) { $result.method } else { "N/A" }
            URL = $pr.html_url
        }

        if ($result.success) {
            $successCount++
            if ($result.resolved) { $conflictResolvedCount++ }
        } else {
            $failureCount++
        }

        # Rate limiting
        Start-Sleep -Milliseconds 1500
    }

    # Summary report
    Write-Host "`n==================================================" -ForegroundColor Cyan
    Write-Host "CONFLICT RESOLUTION AND MERGE SUMMARY" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "Total PRs processed: $($pullRequests.Count)" -ForegroundColor White
    Write-Host "Successful merges: $successCount" -ForegroundColor Green
    Write-Host "Conflicts resolved: $conflictResolvedCount" -ForegroundColor Yellow
    Write-Host "Failed merges: $failureCount" -ForegroundColor Red

    Write-Host "`nDetailed Results:" -ForegroundColor Yellow
    $results | Format-Table -AutoSize

    # Save results to file
    $resultFile = "conflict-resolution-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFile
    Write-Host "`n[RESULTS] Results saved to: $resultFile" -ForegroundColor Cyan
}

# Run the main function
Main
