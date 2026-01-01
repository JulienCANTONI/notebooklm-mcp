# Verify NotebookLM Language - Slow version
# Opens browser and waits so you can check the UI language

$body = @{
    notebook_url = "https://notebooklm.google.com/notebook/725d28e1-4284-4f36-99a2-b6693c2ebf13"
    question = "Hello, what language is the UI in?"
    show_browser = $true
    browser_options = @{
        headless = $false
        slowMo = 2000
    }
} | ConvertTo-Json -Depth 3

Write-Host "==========================================="
Write-Host "  REGARDE LE NAVIGATEUR QUI VA S'OUVRIR"
Write-Host "  Verifie que l'UI est en ANGLAIS"
Write-Host "==========================================="
Write-Host ""

$response = Invoke-RestMethod -Uri "http://localhost:3000/ask" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 120
Write-Host "Reponse recue."
