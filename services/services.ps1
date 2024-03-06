$startTime = Get-Date

$firebaseUriBase = "https://morten1.europe-west1.firebasedatabase.app/"
$machineName = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyyMMddTHHmmss"
$services = Get-Service

$endTime = Get-Date
$executionTime = $endTime - $startTime

$infoToSave = @{
    services = $services
    executionTime = $executionTime
}

$jsonData = $infoToSave | ConvertTo-Json

$firebaseUri = $firebaseUriBase + "machines/$machineName/$timestamp.json"

$response = Invoke-RestMethod -Uri $firebaseUri -Method Put -ContentType "application/json" -Body $jsonData

Write-Output $response
