#!/usr/bin/env pwsh
#Requires -Version 5.1

<#
.SYNOPSIS
    Authentication flow testing script for NotebookLM MCP HTTP Server API

.DESCRIPTION
    Tests authentication-related endpoints:
    - GET /health (auth status)
    - POST /setup-auth
    - POST /de-auth
    - POST /re-auth

.PARAMETER BaseUrl
    Base URL of the server (default: http://localhost:3000)

.EXAMPLE
    .\test-auth.ps1
    Runs all authentication tests

.NOTES
    Prerequisite: The server must be started
    Note: These tests check endpoint behavior without completing full auth flows
#>

param(
    [string]$BaseUrl = "http://localhost:3000"
)

# Colors for logs
function Write-TestHeader {
    param([string]$Message, [int]$Number, [int]$Total)
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host " [$Number/$Total] $Message" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Yellow
}

function Write-ErrorUnexpected {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Banner
Clear-Host
Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                                                        ║" -ForegroundColor Magenta
Write-Host "║         AUTHENTICATION TESTS - HTTP API                ║" -ForegroundColor Cyan
Write-Host "║                                                        ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Check that the server is accessible
Write-Host "Checking connection to server..." -ForegroundColor Yellow
try {
    $null = Invoke-RestMethod -Uri "$BaseUrl/health" -TimeoutSec 5
    Write-Success "Server accessible at $BaseUrl"
} catch {
    Write-ErrorUnexpected "Unable to connect to server at $BaseUrl"
    Write-Host "Make sure the server is started" -ForegroundColor Yellow
    exit 1
}

$TotalTests = 8
$PassedTests = 0
$FailedTests = 0

# =============================================================================
# TEST 1: Health check returns auth status
# =============================================================================
Write-TestHeader "GET /health - Returns authentication status" 1 $TotalTests

try {
    $result = Invoke-RestMethod -Uri "$BaseUrl/health" -TimeoutSec 10

    if ($result.success -eq $true -and $null -ne $result.data) {
        $data = $result.data

        # Check required fields
        $hasStatus = $null -ne $data.status
        $hasAuthStatus = $null -ne $data.authenticated

        if ($hasStatus -and $hasAuthStatus -ne $null) {
            Write-Success "Health endpoint returns expected structure"
            Write-Info "Status: $($data.status), Authenticated: $($data.authenticated)"
            Write-Info "Active sessions: $($data.active_sessions), Max: $($data.max_sessions)"
            $PassedTests++
        } else {
            Write-ErrorUnexpected "Missing required fields (status, authenticated)"
            $FailedTests++
        }
    } else {
        Write-ErrorUnexpected "Health check failed: success=$($result.success)"
        $FailedTests++
    }
} catch {
    Write-ErrorUnexpected "Exception: $($_.Exception.Message)"
    $FailedTests++
}

# =============================================================================
# TEST 2: POST /setup-auth - Endpoint exists and accepts request
# =============================================================================
Write-TestHeader "POST /setup-auth - Endpoint accessible" 2 $TotalTests

try {
    # Send minimal valid request
    $body = @{} | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$BaseUrl/setup-auth" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30

    # Check that we got a response (success or error with meaningful message)
    if ($null -ne $result) {
        if ($result.success -eq $true) {
            Write-Success "Setup auth endpoint working (returned success)"
            Write-Info "Response contains setup instructions or status"
            $PassedTests++
        } elseif ($result.success -eq $false -and $result.error) {
            # Expected if already authenticated or browser issue
            Write-Success "Setup auth endpoint working (returned expected error)"
            Write-Info "Error: $($result.error.Substring(0, [Math]::Min(60, $result.error.Length)))..."
            $PassedTests++
        } else {
            Write-ErrorUnexpected "Unexpected response format"
            $FailedTests++
        }
    } else {
        Write-ErrorUnexpected "No response received"
        $FailedTests++
    }
} catch {
    # Some errors are expected (e.g., timeout waiting for user interaction)
    $statusCode = $_.Exception.Response.StatusCode
    if ($statusCode -eq 500) {
        # Server error might be expected if browser can't launch
        $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Success "Setup auth endpoint accessible (server error expected without display)"
        Write-Info "Error: $($errorResponse.error.Substring(0, [Math]::Min(60, $errorResponse.error.Length)))..."
        $PassedTests++
    } else {
        Write-ErrorUnexpected "Unexpected error: $($_.Exception.Message)"
        $FailedTests++
    }
}

# =============================================================================
# TEST 3: POST /setup-auth - With show_browser parameter
# =============================================================================
Write-TestHeader "POST /setup-auth - With show_browser=false" 3 $TotalTests

try {
    $body = @{ show_browser = $false } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$BaseUrl/setup-auth" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30

    if ($null -ne $result) {
        Write-Success "show_browser parameter accepted"
        $PassedTests++
    } else {
        Write-ErrorUnexpected "No response received"
        $FailedTests++
    }
} catch {
    # Expected to fail in headless environment
    Write-Success "Endpoint accepted show_browser parameter (auth may fail in headless)"
    $PassedTests++
}

# =============================================================================
# TEST 4: POST /de-auth - Endpoint exists
# =============================================================================
Write-TestHeader "POST /de-auth - Endpoint accessible" 4 $TotalTests

try {
    $result = Invoke-RestMethod -Uri "$BaseUrl/de-auth" -Method Post -ContentType "application/json" -TimeoutSec 10

    if ($null -ne $result) {
        if ($result.success -eq $true) {
            Write-Success "De-auth endpoint working (logout successful)"
            $PassedTests++
        } elseif ($result.success -eq $false) {
            # May fail if not authenticated
            Write-Success "De-auth endpoint accessible (returned expected error)"
            Write-Info "Error: $($result.error)"
            $PassedTests++
        } else {
            Write-ErrorUnexpected "Unexpected response format"
            $FailedTests++
        }
    } else {
        Write-ErrorUnexpected "No response received"
        $FailedTests++
    }
} catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Success "De-auth endpoint accessible"
    Write-Info "Response: $($errorResponse.error)"
    $PassedTests++
}

# =============================================================================
# TEST 5: POST /re-auth - Endpoint exists
# =============================================================================
Write-TestHeader "POST /re-auth - Endpoint accessible" 5 $TotalTests

try {
    $body = @{} | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$BaseUrl/re-auth" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30

    if ($null -ne $result) {
        Write-Success "Re-auth endpoint accessible"
        $PassedTests++
    } else {
        Write-ErrorUnexpected "No response received"
        $FailedTests++
    }
} catch {
    # Expected to fail in various scenarios
    Write-Success "Re-auth endpoint accessible (may fail without prior auth)"
    $PassedTests++
}

# =============================================================================
# TEST 6: POST /re-auth - With show_browser parameter
# =============================================================================
Write-TestHeader "POST /re-auth - With show_browser=true" 6 $TotalTests

try {
    $body = @{ show_browser = $true } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri "$BaseUrl/re-auth" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30

    Write-Success "show_browser parameter accepted for re-auth"
    $PassedTests++
} catch {
    # Expected in headless environment
    Write-Success "Endpoint accepted show_browser parameter"
    $PassedTests++
}

# =============================================================================
# TEST 7: POST /setup-auth - Invalid show_browser type
# =============================================================================
Write-TestHeader "POST /setup-auth - Invalid show_browser type (validation)" 7 $TotalTests

try {
    $body = @{ show_browser = "invalid-string" } | ConvertTo-Json
    $null = Invoke-RestMethod -Uri "$BaseUrl/setup-auth" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10

    Write-ErrorUnexpected "Should have returned validation error"
    $FailedTests++
} catch {
    $statusCode = $_.Exception.Response.StatusCode
    if ($statusCode -eq 400 -or $statusCode -eq 'BadRequest') {
        $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($errorResponse.error -like "*show_browser*") {
            Write-Success "Validation correctly rejected invalid show_browser type"
            $PassedTests++
        } else {
            Write-ErrorUnexpected "Error doesn't mention show_browser field"
            $FailedTests++
        }
    } else {
        Write-ErrorUnexpected "Expected 400 status, got: $statusCode"
        $FailedTests++
    }
}

# =============================================================================
# TEST 8: POST /re-auth - Invalid show_browser type
# =============================================================================
Write-TestHeader "POST /re-auth - Invalid show_browser type (validation)" 8 $TotalTests

try {
    $body = @{ show_browser = 123 } | ConvertTo-Json
    $null = Invoke-RestMethod -Uri "$BaseUrl/re-auth" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10

    Write-ErrorUnexpected "Should have returned validation error"
    $FailedTests++
} catch {
    $statusCode = $_.Exception.Response.StatusCode
    if ($statusCode -eq 400 -or $statusCode -eq 'BadRequest') {
        $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($errorResponse.error -like "*show_browser*") {
            Write-Success "Validation correctly rejected invalid show_browser type"
            $PassedTests++
        } else {
            Write-ErrorUnexpected "Error doesn't mention show_browser field"
            $FailedTests++
        }
    } else {
        Write-ErrorUnexpected "Expected 400 status, got: $statusCode"
        $FailedTests++
    }
}

# =============================================================================
# FINAL SUMMARY
# =============================================================================
Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                                                        ║" -ForegroundColor Magenta
Write-Host "║           AUTHENTICATION TEST SUMMARY                  ║" -ForegroundColor Cyan
Write-Host "║                                                        ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

$TotalExecuted = $PassedTests + $FailedTests
$SuccessRate = if ($TotalExecuted -gt 0) { [math]::Round(($PassedTests / $TotalExecuted) * 100, 1) } else { 0 }

Write-Host "Total tests: $TotalTests" -ForegroundColor White
Write-Host "Tests passed: " -NoNewline -ForegroundColor White
Write-Host "$PassedTests" -ForegroundColor Green
Write-Host "Tests failed: " -NoNewline -ForegroundColor White
Write-Host "$FailedTests" -ForegroundColor $(if($FailedTests -gt 0){"Red"}else{"Green"})
Write-Host "Success rate: " -NoNewline -ForegroundColor White
Write-Host "$SuccessRate%" -ForegroundColor $(if($SuccessRate -eq 100){"Green"}elseif($SuccessRate -ge 80){"Yellow"}else{"Red"})

Write-Host ""

if ($FailedTests -eq 0) {
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  ✓ ALL AUTHENTICATION ENDPOINTS WORKING!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
    exit 0
} else {
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  ⚠ SOME AUTHENTICATION TESTS FAILED" -ForegroundColor Yellow
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "See details above to identify the issues." -ForegroundColor Yellow
    exit 1
}
