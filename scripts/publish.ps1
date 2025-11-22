#!/usr/bin/env pwsh
#Requires -Version 5.1

<#
.SYNOPSIS
    Publish script - Push to GitHub and npm in one command

.DESCRIPTION
    Automates the release process:
    1. Verifies git status is clean
    2. Pushes to GitHub (code + tags)
    3. Publishes to npm as public scoped package
    4. Creates GitHub release (optional)

.PARAMETER Version
    Version number (e.g., "1.1.3"). If not provided, uses version from package.json

.PARAMETER SkipNpm
    Skip npm publish step (only push to GitHub)

.PARAMETER SkipGitHub
    Skip GitHub push step (only publish to npm)

.PARAMETER CreateRelease
    Create a GitHub release after pushing

.EXAMPLE
    .\scripts\publish.ps1
    # Uses current version from package.json, pushes to GitHub + npm

.EXAMPLE
    .\scripts\publish.ps1 -Version "1.2.0"
    # Bumps version to 1.2.0, pushes to GitHub + npm

.EXAMPLE
    .\scripts\publish.ps1 -SkipNpm
    # Only pushes to GitHub (no npm publish)

.EXAMPLE
    .\scripts\publish.ps1 -CreateRelease
    # Pushes to GitHub + npm + creates GitHub release

.NOTES
    Prerequisites:
    - Git configured with remote 'origin'
    - npm logged in (npm login)
    - Clean working directory (no uncommitted changes)
#>

param(
    [string]$Version = "",
    [switch]$SkipNpm,
    [switch]$SkipGitHub,
    [switch]$CreateRelease
)

# Colors
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param([string]$Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error-Custom { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }

# Banner
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                                                        ║" -ForegroundColor Magenta
Write-Host "║         PUBLISH TO GITHUB + npm                        ║" -ForegroundColor Cyan
Write-Host "║                                                        ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

# Read package.json
$packageJsonPath = "package.json"
if (-not (Test-Path $packageJsonPath)) {
    Write-Error-Custom "package.json not found. Run this script from the project root."
    exit 1
}

$packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
$currentVersion = $packageJson.version
$packageName = $packageJson.name

Write-Info "Package: $packageName"
Write-Info "Current version: v$currentVersion"

# Determine version to publish
if ($Version) {
    Write-Info "Target version: v$Version (specified)"
    $publishVersion = $Version
} else {
    $publishVersion = $currentVersion
    Write-Info "Target version: v$publishVersion (from package.json)"
}

Write-Host ""

# ============================================================================
# Step 1: Verify Git Status
# ============================================================================
Write-Info "Step 1/4: Checking git status..."

$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Error-Custom "Working directory is not clean. Commit or stash changes first."
    Write-Host "`nUncommitted changes:" -ForegroundColor Yellow
    git status --short
    exit 1
}
Write-Success "Working directory is clean"

# Check if on main branch
$currentBranch = git branch --show-current
if ($currentBranch -ne "main") {
    Write-Warning "You are on branch '$currentBranch', not 'main'"
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Info "Aborted by user"
        exit 0
    }
}

Write-Host ""

# ============================================================================
# Step 2: Push to GitHub
# ============================================================================
if (-not $SkipGitHub) {
    Write-Info "Step 2/4: Pushing to GitHub..."

    # Push code
    Write-Info "Pushing code to origin/$currentBranch..."
    git push origin $currentBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to push to GitHub"
        exit 1
    }
    Write-Success "Code pushed to GitHub"

    # Create and push tag
    $tagName = "v$publishVersion"
    Write-Info "Creating tag $tagName..."

    # Check if tag already exists
    $existingTag = git tag -l $tagName
    if ($existingTag) {
        Write-Warning "Tag $tagName already exists"
        $recreate = Read-Host "Delete and recreate tag? (y/N)"
        if ($recreate -eq "y" -or $recreate -eq "Y") {
            git tag -d $tagName
            git push origin --delete $tagName 2>$null
            Write-Info "Deleted existing tag $tagName"
        } else {
            Write-Info "Skipping tag creation"
        }
    }

    if (-not $existingTag -or $recreate -eq "y" -or $recreate -eq "Y") {
        git tag -a $tagName -m "Release v$publishVersion"
        git push origin $tagName
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Failed to push tag to GitHub"
            exit 1
        }
        Write-Success "Tag $tagName pushed to GitHub"
    }

    Write-Host ""
} else {
    Write-Info "Step 2/4: Skipping GitHub push (--SkipGitHub flag)"
    Write-Host ""
}

# ============================================================================
# Step 3: Publish to npm
# ============================================================================
if (-not $SkipNpm) {
    Write-Info "Step 3/4: Publishing to npm..."

    # Verify npm login
    Write-Info "Checking npm authentication..."
    $npmUser = npm whoami 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Not logged in to npm. Run 'npm login' first."
        exit 1
    }
    Write-Success "Logged in as: $npmUser"

    # Build
    Write-Info "Building project..."
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Build failed"
        exit 1
    }
    Write-Success "Build complete"

    # Publish
    Write-Info "Publishing to npm (public scoped package)..."
    npm publish --access public
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "npm publish failed"
        exit 1
    }
    Write-Success "Published to npm: $packageName@$publishVersion"
    Write-Info "Package URL: https://www.npmjs.com/package/$packageName"

    Write-Host ""
} else {
    Write-Info "Step 3/4: Skipping npm publish (--SkipNpm flag)"
    Write-Host ""
}

# ============================================================================
# Step 4: Create GitHub Release (Optional)
# ============================================================================
if ($CreateRelease -and -not $SkipGitHub) {
    Write-Info "Step 4/4: Creating GitHub release..."

    # Check if gh CLI is installed
    $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $ghInstalled) {
        Write-Warning "GitHub CLI (gh) not installed. Skipping release creation."
        Write-Info "Install from: https://cli.github.com/"
    } else {
        $tagName = "v$publishVersion"
        $releaseTitle = "v$publishVersion"

        Write-Info "Creating release for tag $tagName..."
        gh release create $tagName --title $releaseTitle --generate-notes

        if ($LASTEXITCODE -eq 0) {
            Write-Success "GitHub release created"
        } else {
            Write-Warning "Failed to create GitHub release (non-fatal)"
        }
    }
} else {
    Write-Info "Step 4/4: Skipping GitHub release creation"
}

Write-Host ""

# ============================================================================
# Summary
# ============================================================================
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                        ║" -ForegroundColor Green
Write-Host "║         ✅ PUBLISH SUCCESSFUL!                         ║" -ForegroundColor Green
Write-Host "║                                                        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Success "Published: $packageName@$publishVersion"
Write-Host ""
Write-Info "Links:"
if (-not $SkipGitHub) {
    $repoUrl = $packageJson.repository.url -replace "git\+", "" -replace "\.git$", ""
    Write-Host "  GitHub: $repoUrl" -ForegroundColor White
    Write-Host "  Tag: $repoUrl/releases/tag/v$publishVersion" -ForegroundColor White
}
if (-not $SkipNpm) {
    Write-Host "  npm: https://www.npmjs.com/package/$packageName" -ForegroundColor White
}
Write-Host ""
Write-Info "Installation:"
Write-Host "  npx $packageName@latest" -ForegroundColor White
Write-Host "  npm install -g $packageName" -ForegroundColor White
Write-Host ""
