Write-Host "Decrypting sensitive archives..."

$folders = Get-Content sensitive-folders.txt

foreach ($folder in $folders) {
    $encFile = "$folder.enc"

    if (Test-Path $encFile) {
        Write-Host "Decrypting $encFile → $folder"

        .\fs-encrypt.exe decrypt $encFile .
        .\sdelete -p 7 ".\$encFile"
    }
}

Write-Host "Decryption completed."