# 取证安全工作流

取证安全工作流是一个基于数据物理擦除和加密存储的安全工作流，说明了对于一个git仓库如何在保障取证安全的情况下保持易用性和一致性。

该仓库是一个示例仓库，密码均为`123456`

## 前置内容

1. fs-encrypt: https://github.com/phil616/fs-encrypt
2. sdelete: https://learn.microsoft.com/en-us/sysinternals/downloads/sdelete

```
wget https://download.sysinternals.com/files/SDelete.zip
tar -xf SDelete.zip sdelete.exe
Remove-Item SDelete.zip
wget -O fs-encrypt.exe https://github.com/phil616/fs-encrypt/releases/latest/download/fs-encrypt-windows-amd64.exe
```
注意：

1. wget命令下载的文件可能会被Windows的默认策略标记为`从网络下载的不受信任的文件`导致无法使用，需要先通过`icacls`处理权限后才能启动
2. 第一次启动`sdelete`需要同意终端用户请求声明

## 基础架构

```
sensitive-items.txt     ← 声明哪些目录/文件是机密
encrypt.ps1             ← 一键加密所有机密项目
decrypt.ps1             ← 一键解密
.git/hooks/pre-commit   ← 自动强制加密检查
```

效果：

1. Git 中永远只有 `.enc` 文件
2. 明文目录/文件绝不允许提交
3. 本地自动加解密

### 1.建立敏感项目清单（核心）

创建：

```text
sensitive-items.txt
```

示例：

```text
archive
secrets
private-data
certs
testfile.txt
```

每行一个敏感目录或文件（相对路径）

### Step 2：自动加密脚本（encrypt.ps1）

```powershell
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
```


### Step 3：自动解密脚本（decrypt.ps1）

```powershell
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
```


### Step 5：.gitignore（避免误提交）

```gitignore
archive/
secrets/
private-data/
certs/
testfile.txt
*.tmp
```

### Step 6: 二进制追踪

```
git lfs track *.enc
```

也可以不上传任何加密文件，取决于实际需求
