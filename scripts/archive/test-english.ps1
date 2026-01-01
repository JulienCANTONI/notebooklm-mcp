$body = @{
    question = "Hello, what is this notebook about?"
    notebook_url = "https://notebooklm.google.com/notebook/3f4e9685-333d-429e-8b82-45cee95c6748"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:3000/ask" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 120
$response | ConvertTo-Json -Depth 10
