Write-Host "Encrypting sensitive folders..."

$folders = Get-Content sensitive-folders.txt

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        $encFile = "$folder.enc"

        Write-Host "Encrypting $folder → $encFile"

        .\fs-encrypt.exe encrypt $folder $encFile

        .\sdelete -p 7 -s -r ".\$folder"
    }
}

Write-Host "Encryption completed."