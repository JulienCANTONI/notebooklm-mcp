$body = @{
    source_type = "text"
    title = "E2E Test Source"
    text = "# E2E Test`n`nTest document for E2E testing. Contains info about NotebookLM MCP Server.`n`n## Features`n- REST API`n- Browser automation`n- Multi-account"
    notebook_url = "https://notebooklm.google.com/notebook/abd21688-02a6-4459-953b-30f0612a984e"
    show_browser = $true
} | ConvertTo-Json

Write-Host "Adding source (visible browser)..."
$response = Invoke-RestMethod -Uri "http://localhost:3000/content/sources" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 120
$response | ConvertTo-Json -Depth 5
