Write-Host "Checking for unencrypted sensitive items..."

if (-not (Test-Path "sensitive-items.txt")) {
    Write-Error "sensitive-items.txt not found!"
    exit 1
}

$items = Get-Content sensitive-items.txt
$staged = git diff --cached --name-only

foreach ($item in $items) {

    # 1. 禁止明文文件/目录存在
    if (Test-Path $item) {
        Write-Host "Sensitive item still exists: $item" -ForegroundColor Red
        exit 1
    }

    # 2. 提交加密文件提示
    $enc = "$item.enc"
    if ($staged -notcontains $enc) {
        Write-Host "[Warning]Missing encrypted file in commit: $enc" -ForegroundColor Red
        # 如果强制提交则解除注释
        # exit 1
    }
}

Write-Host "Encryption policy satisfied"
exit 0
