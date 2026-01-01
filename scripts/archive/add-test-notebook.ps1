# Add test notebook to library (no browser needed)
$testNotebookUrl = "https://notebooklm.google.com/notebook/abd21688-02a6-4459-953b-30f0612a984e"

$addBody = @{
    url = $testNotebookUrl
    name = "E2E-Test-Notebook"
    description = "Notebook for E2E testing - can be modified/deleted"
    topics = @("test", "e2e", "automation")
} | ConvertTo-Json

Write-Host "Adding test notebook to library..."
$result = Invoke-RestMethod -Uri "http://localhost:3000/notebooks" -Method POST -ContentType "application/json" -Body $addBody -TimeoutSec 10
$result | ConvertTo-Json -Depth 3
