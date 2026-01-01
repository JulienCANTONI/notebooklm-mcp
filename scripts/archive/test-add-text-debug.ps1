# Test adding a text source with debug logging
$uniqueId = (Get-Date).ToString("HHmmss")
$notebookUrl = "https://notebooklm.google.com/notebook/3e79b7be-9a72-4ac7-aaf7-ac3f450fa96f"

Write-Host "`n=== Testing add_source (text) with debug ===" -ForegroundColor Cyan
Write-Host "Notebook URL: $notebookUrl"
Write-Host "Expected UUID: 3e79b7be-9a72-4ac7-aaf7-ac3f450fa96f`n"

$body = @{
    notebook_url = $notebookUrl
    source_type = "text"
    text = "DEBUG test content $uniqueId - Lorem ipsum dolor sit amet."
    title = "DEBUG-TEST-$uniqueId"
    show_browser = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/content/sources" -Method POST -ContentType "application/json" -Body $body
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.ReadToEnd()
    }
}
