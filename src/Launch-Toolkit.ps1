# 🚀 GitHub PR Toolkit Launcher
# Simple launcher for the unified GitHub PR Management Toolkit

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$Operation = "menu"
)

# Check if main toolkit exists
$toolkitPath = ".\GitHub-PR-Toolkit.ps1"
if (-not (Test-Path $toolkitPath)) {
    Write-Host "Error: GitHub-PR-Toolkit.ps1 not found!" -ForegroundColor Red
    Write-Host "Please ensure the main toolkit file is in the current directory." -ForegroundColor Yellow
    exit 1
}

# If no token provided, prompt for it
if (-not $GitHubToken) {
    Write-Host "GitHub Personal Access Token Required" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This tool requires a GitHub Personal Access Token with the following permissions:" -ForegroundColor White
    Write-Host "  • repo (Full control of private repositories)" -ForegroundColor Yellow
    Write-Host "  • workflow (Update GitHub Action workflows)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Get your token from: https://github.com/settings/tokens" -ForegroundColor Blue
    Write-Host ""
    $GitHubToken = Read-Host "Enter your GitHub token" -AsSecureString
    $GitHubToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GitHubToken))
}

# Build command parameters
$params = @{
    GitHubToken = $GitHubToken
    Operation = $Operation
}

if ($DryRun) {
    $params.DryRun = $true
}

if ($Force) {
    $params.Force = $true
}

# Display configuration
Write-Host ""
    Write-Host "Launching GitHub PR Toolkit" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host "Operation: $Operation" -ForegroundColor White
Write-Host "Dry Run: $DryRun" -ForegroundColor White
Write-Host "Force Mode: $Force" -ForegroundColor White
Write-Host ""

# Launch the toolkit
try {
    & $toolkitPath @params
}
catch {
    Write-Host "Error launching toolkit: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
