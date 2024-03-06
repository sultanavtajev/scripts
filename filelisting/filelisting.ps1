# Lister filer/mapper under en spesifikk mappe
# Kan for eksempel liste opp nedlastinger under downloads
Get-ChildItem -Path "FolderName" | Select-Object Name | Out-File -FilePath .\output1.txt
# Istedenfor "Out-File" kan man bruke "Tee-Object" for å liste opp output i tillegg til å legge inn i en fil.
