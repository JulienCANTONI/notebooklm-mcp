$body = @{
    question = "Hello"
    notebook_url = "https://notebooklm.google.com/notebook/725d28e1-4284-4f36-99a2-b6693c2ebf13"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:3000/ask" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 120
$response | ConvertTo-Json -Depth 10
