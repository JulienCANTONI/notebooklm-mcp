$body = @{
    question = "Hello, what is this notebook about?"
    notebook_url = "https://notebooklm.google.com/notebook/74912e55-34a4-4027-bdcc-8e89badd0efd"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:3000/ask" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 120
$response | ConvertTo-Json -Depth 10
