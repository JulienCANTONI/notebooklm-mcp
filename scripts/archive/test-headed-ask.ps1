# Test /ask avec navigateur visible
$body = @{
    question = "What is IFS therapy?"
    notebook_url = "https://notebooklm.google.com/notebook/3e79b7be-9a72-4ac7-aaf7-ac3f450fa96f"
    show_browser = $true
} | ConvertTo-Json

Write-Host "Envoi requete /ask avec navigateur visible..."
Write-Host "Regardez le navigateur qui va s'ouvrir!"
Write-Host ""

$response = Invoke-RestMethod -Uri "http://localhost:3000/ask" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 180
Write-Host "Reponse: $($response.data.answer)"
