# Test 32: Reject video_style for non-video
$body = @{ notebook_url = "https://notebooklm.google.com/notebook/725d28e1"; content_type = "report"; video_style = "classroom" } | ConvertTo-Json
try {
    Invoke-RestMethod -Uri "http://localhost:3000/content/generate" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 5 | Out-Null
    Write-Host "FAIL"
} catch { Write-Host "PASS" }
