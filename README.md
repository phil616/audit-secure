# 取证安全工作流

取证安全工作流是一个基于数据物理擦除和加密存储的安全工作流，说明了对于一个git仓库如何在保障取证安全的情况下保持易用性和一致性。

## 前置内容

1. fs-encrypt: https://github.com/phil616/fs-encrypt
2. sdelete: https://learn.microsoft.com/en-us/sysinternals/downloads/sdelete

```
wget https://download.sysinternals.com/files/SDelete.zip
tar -xf SDelete.zip sdelete.exe
Remove-Item SDelete.zip
wget -O fs-encrypt.exe https://github.com/phil616/fs-encrypt/releases/latest/download/fs-encrypt-windows-amd64.exe
```

需要注意的是，wget命令下载的文件可能会被Windows的默认策略标记为`从网络下载的不受信任的文件`导致无法使用，需要先通过`icacls`处理权限后才能启动

## 基础架构

```
sensitive-folders.txt   ← 声明哪些目录是机密
encrypt.ps1             ← 一键加密所有机密目录
decrypt.ps1             ← 一键解密
.git/hooks/pre-commit   ← 自动强制加密检查
```

效果：

1. Git 中永远只有 `.enc` 文件
2. 明文目录绝不允许提交
3. 本地自动加解密

### 1.建立敏感目录清单（核心）

创建：

```text
sensitive-folders.txt
```

示例：

```text
archive
secrets
private-data
certs
```

每行一个敏感目录（相对路径）

### Step 2：自动加密脚本（encrypt.ps1）

```powershell
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
```


### Step 3：自动解密脚本（decrypt.ps1）

```powershell
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
```

### Step 4：Git pre-commit 强制策略

```
New-Item .git/hooks/pre-commit -Force
notepad .git/hooks/pre-commit
```

`.git/hooks/pre-commit`

```bash
#!/bin/sh
powershell -ExecutionPolicy Bypass -File scripts/pre-commit.ps1
```

`scripts/pre-commit.ps1`

```powershell
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
```


### Step 5：.gitignore（避免误提交）

```gitignore
archive/
secrets/
private-data/
certs/
*.tmp
```

### Step 6: 二进制追踪

```
git lfs track *.enc
```

也可以不上传任何加密文件，取决于实际需求