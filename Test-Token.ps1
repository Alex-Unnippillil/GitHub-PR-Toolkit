# Simple test script to verify GitHub token
param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken
)

# GitHub API headers
$Headers = @{
    'Authorization' = "token $GitHubToken"
    'Accept' = 'application/vnd.github.v3+json'
    'User-Agent' = 'PowerShell-Test-Script'
}

Write-Host "Testing GitHub token authentication..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $Headers -Method Get

    Write-Host "✅ Authentication successful!" -ForegroundColor Green
    Write-Host "Username: $($response.login)" -ForegroundColor Cyan
    Write-Host "Name: $($response.name)" -ForegroundColor Cyan
    Write-Host "Email: $($response.email)" -ForegroundColor Cyan

    # Test getting user repositories
    Write-Host "`nTesting repository access..." -ForegroundColor Yellow
    $repos = Invoke-RestMethod -Uri "https://api.github.com/user/repos?per_page=5" -Headers $Headers -Method Get

    Write-Host "✅ Repository access successful!" -ForegroundColor Green
    Write-Host "Found $($repos.Count) repositories (showing first 5):" -ForegroundColor Cyan
    foreach ($repo in $repos) {
        Write-Host "  - $($repo.full_name)" -ForegroundColor White
    }

} catch {
    Write-Host "❌ Authentication failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nToken test completed." -ForegroundColor Yellow
