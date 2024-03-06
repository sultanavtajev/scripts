#Lister opp prosesser som kjører
Get-Process | Select-Object Name, Id | Tee-Object -FilePath .\output2.txt
