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

## 启用相关功能

安装方式二选一，**需要管理员权限**，**需重启**

```bash
# PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All

# CMD
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Windows-Subsystem-Linux
DISM /Online /Enable-Feature /All /FeatureName:VirtualMachinePlatform
```

## 更新 WSL 内核

- 下载: <https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi>
- 安装: wsl_update_x64.msi
- 将 WSL2 设置为默认版本: `wsl --set-default-version 2`

## 安装系统

- 不采用官方所说的命令行方式安装（原因：太慢）
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
# 设置镜像并下载 ca-certificates
export MIRROR_URL="http://mirrors.bfsu.edu.cn"
export BRANCH="bookworm"
export COMPONENT="main contrib non-free non-free-firmware"

echo "deb ${MIRROR_URL}/debian/ ${BRANCH} ${COMPONENT}
deb ${MIRROR_URL}/debian/ ${BRANCH}-updates ${COMPONENT}
deb ${MIRROR_URL}/debian-security/ ${BRANCH}-security ${COMPONENT}" | \
sudo tee /etc/apt/sources.list && sudo apt update && sudo apt install -y ca-certificates

# 设置镜像(启用 HTTPS)
export MIRROR_URL="https://mirrors.bfsu.edu.cn"

echo "deb ${MIRROR_URL}/debian/ ${BRANCH} ${COMPONENT}
deb ${MIRROR_URL}/debian/ ${BRANCH}-updates ${COMPONENT}
deb ${MIRROR_URL}/debian-security/ ${BRANCH}-security ${COMPONENT}" | \
sudo tee /etc/apt/sources.list && sudo apt update
```

### 完整更新系统

```bash
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

## 使用 NVIDIA CUDA

### 先决条件

- 确保运行Windows 11或Windows 10版本 21H2 或更高版本。
- 安装 WSL 并为 Linux 分发版设置用户名和密码。
- Windows 上已安装最新 NVIDIA 驱动

### 安装 nvidia-smi

```bash
sudo apt install -y nvidia-smi
```

### 验证

```bash
nvidia-smi
```

- 或者

```bash
sudo apt install -y nvtop
nvtop
```