---
title: "另一种为 LTSC 安装商店的方法"
description: "网上抄来抄去的教程多没意思，来点新鲜的"
date: 2023-04-20T16:05:21+08:00
slug: 8295522e
#image: "cover.png"
tags: [Windows, LTSC, Winget, Store]
categories: Windows
---

网上大部分教程分为两种:

1. 去 <https://store.rg-adguard.net/> 下载离线安装包，使用指令安装
    - 优点: 软件是最新的，下载速度快
    - 缺点: 依赖又多，找对应架构找的眼疼
1. 去 Github 下载 LTSC-Add-MicrosoftStore 这类整合包，一键安装
    - 优点: 方便，一键执行
    - 缺点: 版本落后

- Q: 那有没有什么办法既简便又能直接下到最新版本的方法呢?
- A: 有，用 winget 安装

{{<hint info>}}
**以下内容建议开启代理以获取较快的下载速度**
{{</hint>}}

## 下载 winget

> **`winget` 包含在 `Microsoft.DesktopAppInstaller` 这个包当中，但是由于 `Microsoft.UI.Xaml.2.7` 这个依赖的问题(无法直接下载)，我们又无法直接安装 `Microsoft.DesktopAppInstaller`，下面是折中的解决方法**

### 安装依赖

- 除了 `Microsoft.UI.Xaml.2.7`，winget 还依赖 `Microsoft.VCLibs.x64.14.00.Desktop`

1. 前往 <https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx> 下载这个依赖
    - 或者使用 PowerShell 指令 (并不建议): `Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx`
1. 使用 `Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx` 指令安装

### 获取最新版本的 winget

1. 下载 <https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle>
1. 用压缩软件打开 `Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle`, 解压出 `AppInstaller_x64.msix` 或 `AppInstaller_x86.msix` 文件 (取决于电脑架构)
1. 将解压出来的 msix 文件再次解压成目录
1. 打开目录，在目录空白处 `Shift` + `右键`，`在此处打开 PowerShell 窗口`
1. 使用 `.\winget --info` 检测 winget 是否可用

## 安装 Microsoft Store

只要 winget 能用，剩下的就简单了

- 安装微软商店:

```pwsh
.\winget install 9WZDNCRFJBMP
```

## 其他常用组件的安装

### Xbox

- 先安装 Xbox Identity Provider，否则会出现 Xbox 无法登录的情况

```pwsh
.\winget install 9WZDNCRD1HKW
```

- 安装 Xbox 本体

```pwsh
.\winget install 9MV0B5HZVK9Z
```

### Xbox Game Bar

Windows 10 自带的小工具 (但是 LTSC 没有)

```pwsh
.\winget install 9NZKPSTSNW4P
```

## Tips

### 部分软件的 ProductID

- `9N0DX20HK701`: Windows Terminal
- `9NBLGGH4NNS1`: Microsoft.DesktopAppInstaller (即 winget 自身)

Tips:

- 使用 `https://apps.microsoft.com/store/detail/{ProductID}` 可以查看软件的商店页面
- 例如 <https://apps.microsoft.com/store/detail/9NBLGGH4NNS1>

### 解除脚本运行限制 (需管理员权限)

```pwsh
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
```

### 如果你非要手动安装 DesktopAppInstaller

如果你解决了 `Microsoft.UI.Xaml.2.7` 依赖问题，安装了 `Microsoft.DesktopAppInstaller` 发现 winget 依旧无法使用，但是报错不是找不到指令

**原因:** 不知道，反正和 `License` 有关

**解决办法:** 

1. 前往 <https://github.com/microsoft/winget-cli/releases/>，下载对应版本的 `xxxxxxxx_License1.xml`
2. 在 `Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle` 所在的目录下执行 **(需要管理员权限)**:

```pwsh
Add-AppxProvisionedPackage -Online -PackagePath .\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -LicensePath .\*_License1.xml
```