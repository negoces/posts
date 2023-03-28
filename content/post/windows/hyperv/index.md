---
title: "Hyper-V 笔记"
description: "Windows Hyper-V 的使用指南"
date: 2023-03-28T20:56:55+08:00
slug: 494d87b4
#image: "cover.png"
tags: [Hyper-V, VM, Windows]
categories: Hyper-V
---

## 安装条件

- Windows 10 专业版及以上
- CPU 支持二级地址转换 (SLAT)
- CPU 支持虚拟化功能
- RAM: 4GB+

## 命令行安装

安装方式二选一，**需要管理员权限**，**需重启**

```bash
# PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
# CMD
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V
```

## 命令操作

- <https://learn.microsoft.com/zh-cn/virtualization/hyper-v-on-windows/quick-start/try-hyper-v-powershell>

### 显示命令列表

```pwsh
Get-Command -Module hyper-v | Out-GridView
```

### 返回虚拟机列表

```pwsh
Get-VM
```
