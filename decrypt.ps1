Write-Host "Decrypting sensitive items..."

if (-not (Test-Path "sensitive-items.txt")) {
    Write-Error "sensitive-items.txt not found!"
    exit 1
}

$items = Get-Content sensitive-items.txt

foreach ($item in $items) {
    $encFile = "$item.enc"

    if (Test-Path $encFile) {
        Write-Host "Decrypting $encFile → $item"

        .\fs-encrypt.exe decrypt $encFile .
        .\sdelete -p 7 ".\$encFile"
    }
}

Write-Host "Decryption completed."
