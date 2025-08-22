# 🚀 Pull Request Merger for Windows
# Wrapper around the unified GitHub PR Toolkit

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken,

    [Parameter(Mandatory=$false)]
    [ValidateSet('menu','status','merge','close','force')]
    [string]$Operation = 'menu',

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Locate main toolkit
$toolkitPath = Join-Path $PSScriptRoot 'GitHub-PR-Toolkit.ps1'
if (-not (Test-Path $toolkitPath)) {
    Write-Host 'Error: GitHub-PR-Toolkit.ps1 not found next to this launcher.' -ForegroundColor Red
    exit 1
}

# Prompt for token if not supplied
if (-not $GitHubToken) {
    Write-Host 'GitHub Personal Access Token Required' -ForegroundColor Cyan
    Write-Host 'Get a token at: https://github.com/settings/tokens (repo, workflow)' -ForegroundColor Yellow
    $secure = Read-Host 'Enter your GitHub token' -AsSecureString
    $GitHubToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    )
}

# Build params
$params = @{
    GitHubToken = $GitHubToken
    Operation = $Operation
}
if ($DryRun) { $params.DryRun = $true }
if ($Force) { $params.Force = $true }

Write-Host ''
Write-Host 'Launching Pull Request Merger' -ForegroundColor Green
Write-Host "Operation: $Operation" -ForegroundColor White
Write-Host "Dry Run : $($DryRun.IsPresent)" -ForegroundColor White
Write-Host "Force   : $($Force.IsPresent)" -ForegroundColor White
Write-Host ''

# Delegate to toolkit
& $toolkitPath @params
