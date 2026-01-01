# Test FULL: Language option (1 test)
$notebookUrl = "https://notebooklm.google.com/notebook/3e79b7be-9a72-4ac7-aaf7-ac3f450fa96f"

Write-Host "`n=== Testing language = fr ===" -ForegroundColor Cyan

$body = @{
    notebook_url = $notebookUrl
    content_type = "presentation"
    language = "fr"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/content/generate" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 300
    if ($response.success) {
        Write-Host "PASSED" -ForegroundColor Green
    } else {
        Write-Host "FAILED: $($response.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
