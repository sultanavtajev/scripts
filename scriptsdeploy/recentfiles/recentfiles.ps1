# Lister opp de nyligste brukte filene


# Tatt insperasjon fra: https://jdhitsolutions.com/blog/powershell/1156/powershell-ise-most-recent-files/
# Import-CSV $global:ISERecent | Sort LastEdit | Select -Last $count | Sort LastEdit -Descending | Tee-Object -FilePath .\output3.txt
# Fungerer ikke



# En annen måte å gjøre det på:
# Definerer nummer på hvor mange filer vi vil ha tak i
$count = 20

# Henter filer fra hele filsystemet til maskinen, sorterer listen med LastWriteTime og skriver ut de nyligste filene
# Insperasjon fra: https://www.pdq.com/blog/using-get-childitem-find-files/
Get-ChildItem -Path C:\ -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First $count FullName, LastWriteTime | Tee-Object -FilePath .\output3.txt
# Tar litt tid å kjøre
