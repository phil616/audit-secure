Write-Host "Checking for unencrypted sensitive folders..."

$folders = Get-Content sensitive-folders.txt
$staged = git diff --cached --name-only

foreach ($folder in $folders) {

    # 1. 禁止明文目录存在
    if (Test-Path $folder) {
        Write-Host "Sensitive folder still exists: $folder" -ForegroundColor Red
        exit 1
    }

    # 2. 提交加密文件提示
    $enc = "$folder.enc"
    if ($staged -notcontains $enc) {
        Write-Host "[Warning]Missing encrypted file in commit: $enc" -ForegroundColor Red
        # 如果强制提交则解除注释
        # exit 1
    }
}

Write-Host "Encryption policy satisfied"
exit 0