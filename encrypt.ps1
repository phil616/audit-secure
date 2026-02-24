Write-Host "Encrypting sensitive items..."

if (-not (Test-Path "sensitive-items.txt")) {
    Write-Error "sensitive-items.txt not found!"
    exit 1
}

$items = Get-Content sensitive-items.txt

foreach ($item in $items) {
    if (Test-Path $item) {
        $encFile = "$item.enc"
        
        if (Test-Path -Path $item -PathType Container) {
            # It's a directory
            Write-Host "Encrypting folder $item → $encFile"
            .\fs-encrypt.exe encrypt $item $encFile
            .\sdelete -p 7 -s -r ".\$item"
        } else {
            # It's a file
            Write-Host "Encrypting file $item → $encFile"
            .\fs-encrypt.exe encrypt-item $item $encFile
            .\sdelete -p 7 ".\$item"
        }
    } else {
        Write-Warning "Item not found: $item"
    }
}

Write-Host "Encryption completed."
