---
title: "在 Windows 上安装 Git 并启用 GPG 签名"
description: "使用 Winget 快速配置 Git 环境"
date: 2023-04-20T15:34:13+08:00
slug: 205a60cb
#image: "cover.png"
tags: [Windows, Winget, Git, GPG]
categories: Development
---

## 安装 Git

```bash
winget install Git.Git
```

## 安装 Gpg4win

```bash
winget install GnuPG.Gpg4win
```

## 生成&导入 GPG 密钥

### 生成密钥

**Tips:** 不要加密，否则 VS Code 的 Git 扩展无法进行提交

```bash
gpg --full-generate-key
# or
gpg --gen-key
```

### 导入密钥

```bash
gpg --import private_or_public.key
```

## 配置 Git

### 基本配置

设置 **用户名** 和 **邮箱** (需要和注册平台时用的邮箱对应)

```bash
git config --global user.name "username"
git config --global user.email "user@example.com"
```

### 启用签名

1. 使用 `gpg --list-secret-keys --keyid-format=long` 列出所有密钥
1. 记下 `sec` 的第二行密钥，并记录为 `${KEY_ID}`
1. 设置 git 签名所使用的密钥 `git config --global user.signingkey ${KEY_ID}`
1. 使 Git 默认使用 GPG 签名 `git config --global commit.gpgsign true`
1. 使用 `gpg --armor --export ${KEY_ID}` 导出公钥并添加至平台

## 常见错误

### 无法为数据签名

**症状:**

```bash
# 报错:
error: gpg failed to sign the data
fatal: failed to write commit
# 或者
错误：gpg 无法为数据签名
致命错误：无法写提交对象
```

并且使用 `git commit -S -m "..."` 时要求输入密码并可以提交成功

**原因:**

VS Code 等工具无法弹出密码输入界面进行解密操作

**解决方法:**

删除密钥的密码保护: `gpg --change-passphrase <key_id>`，输入当前密码后再输入空密码即可删除
