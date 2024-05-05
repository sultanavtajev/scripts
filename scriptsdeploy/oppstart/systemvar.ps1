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

# Sjekk om et dokument med samme navn allerede eksisterer
$duplicateDocument = $null
try {
    $duplicateDocument = Invoke-RestMethod -Uri $documentUrl -Method Get
} catch {
    # Hvis dokumentet ikke finnes, vil dette kaste en feil, som vi kan ignorere
}

# Hvis et dokument med samme navn eksisterer under kolleksjonen "machines"
if ($duplicateDocument) {
    # Opprett en ny kolleksjon med dagens dato og tid som navn
    $collectionName = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")

    # Opprett URL-en for den nye kolleksjonen
    $newCollectionUrl = "$documentUrl/$collectionName"

    # Opprett en enkel JSON-kropp for POST-forespørselen
    $body = @{
        fields = @{
            # Legg til informasjonen du vil lagre under den nye kolleksjonen
            name = @{
                stringValue = $pcName
            }
            status = @{
                stringValue = "Operational"
            }
            userName = @{
                stringValue = $userName
            }
            userDomainName = @{
                stringValue = $userDomainName
            }
            osVersion = @{
                stringValue = $osVersion.ToString()
            }
            commandLine = @{
                stringValue = $commandLineArgs -join " "
            }
            currentDirectory = @{
                stringValue = $currentDirectory
            }
            systemDirectory = @{
                stringValue = $systemDirectory
            }
            processorCount = @{
                integerValue = $processorCount
            }
        }
    } | ConvertTo-Json -Depth 10

    # Definer HTTP-headere
    $headers = @{
        "Content-Type" = "application/json"
    }

    # Send POST-forespørselen for å opprette den nye kolleksjonen og lagre informasjonen
    try {
        $response = Invoke-RestMethod -Uri $newCollectionUrl -Method Post -Body $body -Headers $headers
        Write-Output "Response from Firestore: $response"
    } catch {
        Write-Error "Error sending data to Firestore: $_"
    }
} else {
    # Opprett en ny kolleksjon med dagens dato og tid som navn
    $collectionName = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")

    # Opprett URL-en for den nye kolleksjonen
    $newCollectionUrl = "$documentUrl/$collectionName"

    # Opprett en enkel JSON-kropp for POST-forespørselen
    $body = @{
        fields = @{
            # Legg til informasjonen du vil lagre under den nye kolleksjonen
            name = @{
                stringValue = $pcName
            }
            status = @{
                stringValue = "Operational"
            }
            userName = @{
                stringValue = $userName
            }
            userDomainName = @{
                stringValue = $userDomainName
            }
            osVersion = @{
                stringValue = $osVersion.ToString()
            }
            commandLine = @{
                stringValue = $commandLineArgs -join " "
            }
            currentDirectory = @{
                stringValue = $currentDirectory
            }
            systemDirectory = @{
                stringValue = $systemDirectory
            }
            processorCount = @{
                integerValue = $processorCount
            }
        }
    } | ConvertTo-Json -Depth 10

    # Definer HTTP-headere
    $headers = @{
        "Content-Type" = "application/json"
    }

    # Send POST-forespørselen for å opprette den nye kolleksjonen og lagre informasjonen
    try {
        $response = Invoke-RestMethod -Uri $newCollectionUrl -Method Post -Body $body -Headers $headers
        Write-Output "Response from Firestore: $response"
    } catch {
        Write-Error "Error sending data to Firestore: $_"
    }
}
