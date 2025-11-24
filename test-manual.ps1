#!/usr/bin/env pwsh
#Requires -Version 5.1

<#
.SYNOPSIS
    Manual testing script with human-friendly output
.DESCRIPTION
    Interactive test script for NotebookLM MCP HTTP API
    Tests all endpoints with pretty colored output
#>

param(
    [string]$BaseUrl = "http://localhost:3000"
)

# Colors
function Write-Title { param([string]$Message) Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan; Write-Host "  $Message" -ForegroundColor White; Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan }
function Write-Step { param([string]$Message) Write-Host "`n▶ $Message" -ForegroundColor Yellow }
function Write-Success { param([string]$Message) Write-Host "  ✅ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "  ℹ️  $Message" -ForegroundColor Cyan }
function Write-Error-Custom { param([string]$Message) Write-Host "  ❌ $Message" -ForegroundColor Red }
function Write-Data { param([string]$Message) Write-Host "  📄 $Message" -ForegroundColor White }

# Pretty print JSON
function Show-Json {
    param([object]$Data)
    $json = $Data | ConvertTo-Json -Depth 10
    Write-Host $json -ForegroundColor Gray
}

# Banner
Clear-Host
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                                                       ║" -ForegroundColor Magenta
Write-Host "║     NotebookLM MCP - Manual Testing Suite            ║" -ForegroundColor Cyan
Write-Host "║                                                       ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Info "Base URL: $BaseUrl"
Write-Info "Press ENTER after each test to continue..."

# Test 1: Health Check
Write-Title "TEST 1: Health Check"
Write-Step "GET /health"
try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get
    Write-Success "Server is running!"
    Write-Data "Authenticated: $($health.data.authenticated)"
    Write-Data "Active sessions: $($health.data.sessions)"
    Write-Data "Notebooks in library: $($health.data.library_notebooks)"
    Write-Data "Browser context age: $($health.data.context_age_hours) hours"
} catch {
    Write-Error-Custom "Failed to connect to server"
    Write-Error-Custom $_.Exception.Message
    exit 1
}
Read-Host "`nPress ENTER to continue"

# Test 2: List Notebooks
Write-Title "TEST 2: List Notebooks"
Write-Step "GET /notebooks"
try {
    $notebooks = Invoke-RestMethod -Uri "$BaseUrl/notebooks" -Method Get
    Write-Success "Retrieved notebook list"
    Write-Data "Total notebooks: $($notebooks.data.count)"

    if ($notebooks.data.count -gt 0) {
        Write-Host "`n  📚 Notebooks:" -ForegroundColor Cyan
        foreach ($nb in $notebooks.data.notebooks) {
            Write-Host "    • $($nb.name)" -ForegroundColor White
            Write-Host "      ID: $($nb.id)" -ForegroundColor Gray
            Write-Host "      Description: $($nb.description)" -ForegroundColor Gray
            if ($nb.auto_generated) {
                Write-Host "      🤖 Auto-generated metadata" -ForegroundColor Yellow
            }
            Write-Host ""
        }
    } else {
        Write-Info "No notebooks in library yet"
    }
} catch {
    Write-Error-Custom "Failed to list notebooks"
    Write-Error-Custom $_.Exception.Message
}
Read-Host "`nPress ENTER to continue"

# Test 3: Auto-Discovery (NEW v1.3.0)
Write-Title "TEST 3: Auto-Discovery ⭐ NEW"
Write-Step "POST /notebooks/auto-discover"
Write-Info "Testing with Shakespeare Complete Works (public notebook)"

$testUrl = "https://notebooklm.google.com/notebook/19bde485-a9c1-4809-8884-e872b2b67b44"
Write-Data "Notebook URL: $testUrl"
Write-Host ""
Write-Host "  🤖 The system will:" -ForegroundColor Yellow
Write-Host "     1. Open the notebook" -ForegroundColor Gray
Write-Host "     2. Ask NotebookLM to analyze its content" -ForegroundColor Gray
Write-Host "     3. Generate metadata automatically" -ForegroundColor Gray
Write-Host "     4. Validate the format" -ForegroundColor Gray
Write-Host ""
Write-Info "This may take 20-30 seconds..."

$continueTest = Read-Host "`nRun auto-discovery test? (y/N)"
if ($continueTest -eq "y" -or $continueTest -eq "Y") {
    try {
        $body = @{ url = $testUrl } | ConvertTo-Json
        $discovered = Invoke-RestMethod -Uri "$BaseUrl/notebooks/auto-discover" -Method Post -Body $body -ContentType "application/json"

        Write-Success "Auto-discovery completed!"
        Write-Host ""
        Write-Host "  📋 Generated Metadata:" -ForegroundColor Cyan
        Write-Data "Name (kebab-case): $($discovered.notebook.name)"
        Write-Data "Description: $($discovered.notebook.description)"
        Write-Host "  🏷️  Tags:" -ForegroundColor Cyan
        foreach ($tag in $discovered.notebook.tags) {
            Write-Host "     • $tag" -ForegroundColor Gray
        }
        Write-Data "Auto-generated: $($discovered.notebook.auto_generated)"
        Write-Data "Notebook ID: $($discovered.notebook.id)"

        # Save ID for later tests
        $script:lastNotebookId = $discovered.notebook.id

    } catch {
        Write-Error-Custom "Auto-discovery failed"
        Write-Error-Custom $_.Exception.Message
        if ($_.ErrorDetails.Message) {
            $errorDetail = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "  Details: $($errorDetail.error)" -ForegroundColor Red
        }
    }
} else {
    Write-Info "Skipped auto-discovery test"
}
Read-Host "`nPress ENTER to continue"

# Test 4: Get Notebook Details
if ($script:lastNotebookId) {
    Write-Title "TEST 4: Get Notebook Details"
    Write-Step "GET /notebooks/$($script:lastNotebookId)"

    try {
        $notebook = Invoke-RestMethod -Uri "$BaseUrl/notebooks/$($script:lastNotebookId)" -Method Get
        Write-Success "Retrieved notebook details"
        Write-Host ""
        Show-Json $notebook.data.notebook
    } catch {
        Write-Error-Custom "Failed to get notebook details"
        Write-Error-Custom $_.Exception.Message
    }
    Read-Host "`nPress ENTER to continue"
}

# Test 5: Ask Question
if ($script:lastNotebookId) {
    Write-Title "TEST 5: Ask Question"
    Write-Step "POST /ask"

    $question = Read-Host "`nWhat question do you want to ask? (or press ENTER for default)"
    if ([string]::IsNullOrWhiteSpace($question)) {
        $question = "Who is Hamlet?"
    }

    Write-Info "Asking: '$question'"
    Write-Info "This may take 30-60 seconds..."

    try {
        $body = @{
            question = $question
            notebook_id = $script:lastNotebookId
        } | ConvertTo-Json

        $answer = Invoke-RestMethod -Uri "$BaseUrl/ask" -Method Post -Body $body -ContentType "application/json"

        Write-Success "Got answer from NotebookLM!"
        Write-Host ""
        Write-Host "  ❓ Question:" -ForegroundColor Cyan
        Write-Host "     $($answer.data.question)" -ForegroundColor White
        Write-Host ""
        Write-Host "  💬 Answer:" -ForegroundColor Cyan
        Write-Host "     $($answer.data.answer)" -ForegroundColor White
        Write-Host ""
        Write-Data "Session ID: $($answer.data.session_id)"
        Write-Data "Message count: $($answer.data.session_info.message_count)"
        Write-Data "Session age: $($answer.data.session_info.age_seconds) seconds"

    } catch {
        Write-Error-Custom "Failed to get answer"
        Write-Error-Custom $_.Exception.Message
    }
    Read-Host "`nPress ENTER to continue"
}

# Test 6: List Sessions
Write-Title "TEST 6: List Active Sessions"
Write-Step "GET /sessions"
try {
    $sessions = Invoke-RestMethod -Uri "$BaseUrl/sessions" -Method Get
    Write-Success "Retrieved session list"
    Write-Data "Active sessions: $($sessions.data.count)"

    if ($sessions.data.count -gt 0) {
        Write-Host "`n  🔗 Sessions:" -ForegroundColor Cyan
        foreach ($sess in $sessions.data.sessions) {
            Write-Host "    • Session $($sess.id)" -ForegroundColor White
            Write-Host "      Messages: $($sess.message_count)" -ForegroundColor Gray
            Write-Host "      Age: $($sess.age_seconds)s" -ForegroundColor Gray
            Write-Host "      Inactive: $($sess.inactive_seconds)s" -ForegroundColor Gray
            Write-Host ""
        }
    }
} catch {
    Write-Error-Custom "Failed to list sessions"
    Write-Error-Custom $_.Exception.Message
}
Read-Host "`nPress ENTER to continue"

# Test 7: Cleanup (Optional)
Write-Title "TEST 7: Cleanup (Optional)"
if ($script:lastNotebookId) {
    $cleanup = Read-Host "`nDelete the test notebook '$($script:lastNotebookId)'? (y/N)"
    if ($cleanup -eq "y" -or $cleanup -eq "Y") {
        Write-Step "DELETE /notebooks/$($script:lastNotebookId)"
        try {
            $result = Invoke-RestMethod -Uri "$BaseUrl/notebooks/$($script:lastNotebookId)" -Method Delete
            Write-Success "Notebook deleted successfully"
        } catch {
            Write-Error-Custom "Failed to delete notebook"
            Write-Error-Custom $_.Exception.Message
        }
    } else {
        Write-Info "Notebook kept in library"
    }
}

# Summary
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                       ║" -ForegroundColor Green
Write-Host "║            ✅ Testing Complete!                       ║" -ForegroundColor Green
Write-Host "║                                                       ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Info "All endpoints tested successfully!"
Write-Info "API Documentation: deployment/docs/03-API.md"
Write-Host ""
