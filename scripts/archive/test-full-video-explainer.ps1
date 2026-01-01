# Test FULL: Video format = explainer
$notebookUrl = "https://notebooklm.google.com/notebook/3e79b7be-9a72-4ac7-aaf7-ac3f450fa96f"

Write-Host "`n=== FULL TEST: Video Format = explainer ===" -ForegroundColor Cyan

$body = @{
    notebook_url = $notebookUrl
    content_type = "video"
    video_format = "explainer"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/content/generate" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 300
    if ($response.success) {
        Write-Host "PASSED" -ForegroundColor Green
        Write-Host "Content length: $($response.data.content.Length) chars"
    } else {
        Write-Host "FAILED: $($response.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
