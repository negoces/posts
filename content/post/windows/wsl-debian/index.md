---
title: "Windows Subsystem Linux: Debian 使用笔记"
description: "适用于 Linux 的 Windows 子系统"
date: 2023-04-10T20:50:34+08:00
slug: 149a9cfc
#image: "cover.png"
tags: [Windows, WSL2, WSLg, Debian]
categories: WSL
---

> 适用于 Linux 的 Windows 子系统 (WSL) 可让开发人员直接在 Windows 上按原样运行 GNU/Linux 环境（包括大多数命令行工具、实用工具和应用程序），且不会产生传统虚拟机或双启动设置开销。

## 安装要求

- 对于 x64 系统：版本 1903 或更高版本，内部版本为 18362 或更高版本。
- 对于 ARM64 系统：版本 2004 或更高版本，内部版本为 19041 或更高版本。

## 启用 WSL 功能

安装方式二选一，**需要管理员权限**，**需重启**

> **[未验证]** 好像这个也行： `wsl --install --no-distribution --web-download`

### 使用 PowerShell

- 启用
    ```pwsh
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
    ```
- 禁用
    ```pwsh
    Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -Remove
    Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -Remove
    ```

### 使用 DISM

在 CMD 和 PowerShell 中均可使用

- 启用
    ```bash
    DISM /Online /Enable-Feature /All /NoRestart /FeatureName:Microsoft-Windows-Subsystem-Linux
    DISM /Online /Enable-Feature /All /NoRestart /FeatureName:VirtualMachinePlatform
    ```
- 禁用
    ```bash
    DISM /Online /Disable-Feature /Remove /NoRestart /FeatureName:Microsoft-Windows-Subsystem-Linux
    DISM /Online /Disable-Feature /Remove /NoRestart /FeatureName:VirtualMachinePlatform
    ```

## 安装及更新 WSL 内核

- 查看当前状态
    ```bash
    wsl --status
    wsl --version
    ```
- 安装/更新内核 **(需管理员权限，需要代理)**
    ```bash
    wsl --update --web-download
    ```
- 将 WSL2 设置为默认版本
    ```bash
    wsl --set-default-version 2
    ```

## 安装系统

也是两种方式：命令行安装、手动安装

### 命令行方式安装

- 下载需要代理
- 添加 `--web-download` 参数下载最新的镜像 (否则 Debian 9 将等着你)

```bash
wsl --install --distribution Debian --web-download
```

### 手动安装

- 将直接下载 appxbundle 后安装

1. 前往: <https://store.rg-adguard.net/>
2. 搜索方式从 `URL (Link)` 改为 `Productid`
3. 搜索 `9MSVKQC78PK6`
4. 下载 `TheDebianProject.DebianGNULinux_<version>_neutral_~_76v4gfsz19hv4.appxbundle`
5. 使用 `Add-AppxPackage <FileName>` 安装
6. 在开始菜单中打开，并设置用户名和密码

## 设置系统

### 设置镜像

```bash
# 设置镜像所需关键字
export MIRROR_URL="http://mirrors.bfsu.edu.cn"
export BRANCH="bookworm"
export COMPONENT="main contrib non-free non-free-firmware"

# 将镜像配置写入 sources.list
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb ${MIRROR_URL}/debian/ ${BRANCH} ${COMPONENT}
deb ${MIRROR_URL}/debian/ ${BRANCH}-updates ${COMPONENT}
deb ${MIRROR_URL}/debian-security/ ${BRANCH}-security ${COMPONENT}
EOF

# 更新索引并安装 ca-certificates (HTTPS 依赖)
sudo apt update && sudo apt install -y ca-certificates

# 启用 HTTPS 并更新索引
sudo sed -i 's/http:/https:/g' /etc/apt/sources.list && sudo apt update
```

### 完整更新系统

```bash
# 更新索引并更新系统
sudo apt update && sudo apt full-upgrade -y

# 卸载无用包
sudo apt autopurge -y
```

### 设置时区和语言

需重启 WSL 生效

```bash
# 设置时区
sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 取消语言生成文件注释
sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sudo sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen

# 生成语言并配置
sudo /usr/sbin/locale-gen
echo 'LANG="zh_CN.UTF-8"' | sudo tee /etc/locale.conf
```

### 测试 WSLg

> 适用于 Linux 的 Windows 子系统 (WSL) 现在支持在 Windows 上以完全集成的桌面体验 (X11 和 Wayland) 运行 Linux GUI 应用程序。

- 安装 `vulkan-tools`

```bash
sudo apt install -y vulkan-tools
```

- 运行 `vkcube` 或 `vkcube-wayland`

#### Intel GPU 加速

安装下面的驱动，然后重启电脑：

<https://www.intel.cn/content/www/cn/zh/download/19344/intel-graphics-windows-dch-drivers.html>

## 使用 NVIDIA CUDA

### 先决条件

- 确保运行Windows 11或Windows 10版本 21H2 或更高版本。
- 安装 WSL 并为 Linux 分发版设置用户名和密码。
- Windows 上已安装最新 NVIDIA 驱动

### 修复 libcuda.so.1 链接

**问题表现：** 在 apt 安装软件时报错

```bash
ldconfig: /usr/lib/wsl/lib/libcuda.so.1 is not a symbolic link
```

**解决方法：** 在 Windows 上使用 **管理员权限** 运行(PowerShell):

```pwsh
Set-Location C:\Windows\System32\lxss\lib
Remove-Item libcuda.so
Remove-Item libcuda.so.1
New-Item -ItemType SymbolicLink -Path "libcuda.so.1" -Target "libcuda.so.1.1"
New-Item -ItemType SymbolicLink -Path "libcuda.so" -Target "libcuda.so.1.1"
```

然后重启 WSL，在 WSL 内检查 CUDA 版本:

```bash
/usr/lib/wsl/lib/nvidia-smi
```
