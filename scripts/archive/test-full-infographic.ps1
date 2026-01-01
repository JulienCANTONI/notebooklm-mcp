# Test FULL: Infographic Formats (2 tests)
$notebookUrl = "https://notebooklm.google.com/notebook/3e79b7be-9a72-4ac7-aaf7-ac3f450fa96f"
$formats = @("horizontal", "vertical")

$passed = 0
$failed = 0

foreach ($format in $formats) {
    Write-Host "`n=== Testing infographic_format = $format ===" -ForegroundColor Cyan

    $body = @{
        notebook_url = $notebookUrl
        content_type = "infographic"
        infographic_format = $format
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3000/content/generate" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 300
        if ($response.success) {
            Write-Host "  PASSED" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  FAILED: $($response.error)" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
        $failed++
    }
    Start-Sleep -Seconds 3
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Yellow
Write-Host "Passed: $passed / $($formats.Count)"
