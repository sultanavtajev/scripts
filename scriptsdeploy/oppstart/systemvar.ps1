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
        stringValue = $pcName}
        status = @{ stringValue = "Operational" }
        userName = @{ stringValue = $userName }
        userDomainName = @{ stringValue = $userDomainName }
        osVersion = @{ stringValue = $osVersion.ToString() }
        commandLine = @{ stringValue = $commandLineArgs -join " " }
        currentDirectory = @{ stringValue = $currentDirectory }
        systemDirectory = @{ stringValue = $systemDirectory }
        processorCount = @{ integerValue = $processorCount }
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
