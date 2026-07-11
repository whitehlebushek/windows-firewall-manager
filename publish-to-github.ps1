#Requires -Version 5.1
<#
.SYNOPSIS
  Helper script to publish Windows Firewall Manager to GitHub.
#>
param(
    [Parameter(Mandatory=$true)][string]$GitHubUsername,
    [string]$RepoName = 'windows-firewall-manager',
    [string]$Tag = 'v1.0.0-etalon'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'Git not found. Install from https://git-scm.com/download/win' -ForegroundColor Yellow
    Write-Host 'Manual steps are in README.md section "Публикация на GitHub"'
    exit 1
}

if (-not (Test-Path '.git')) {
    git init
    git add .
    git commit -m "Release $Tag: Windows Firewall Manager with Russian GUI"
}

$remote = "https://github.com/$GitHubUsername/$RepoName.git"
$existing = git remote get-url origin 2>$null
if (-not $existing) { git remote add origin $remote }
else { git remote set-url origin $remote }

git branch -M main
Write-Host "Push to: $remote" -ForegroundColor Cyan
Write-Host 'Run: git push -u origin main'
Write-Host "Then create GitHub Release $Tag and attach:"
Write-Host "  releases/windows-firewall-manager-v1.0.0-etalon.zip"
