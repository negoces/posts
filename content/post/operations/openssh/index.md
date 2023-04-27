---
title: "OpenSSH 基础指南"
description: "OpenSSH 的一些常用指令及密钥登陆指南"
date: 2023-04-28T02:25:39+08:00
slug: ec7e8223
#image: "cover.png"
tags: [OpenSSH, ed25519, authorized_keys]
categories: Operations
---

## 生成密钥对

- 默认使用 RSA 生成，公钥较长，这里换成 ED25519

```bash
ssh-keygen -t ed25519
```

- 若均采用默认选项，公私钥的位置如下：
    - 私钥：`${HOME}/.ssh/id_ed25519`
    - 公钥：`${HOME}/.ssh/id_ed25519.pub`

## 密钥登陆

- 在目标主机上创建 `~/.ssh/authorized_keys`

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

- 导入公钥

```bash
echo 'ssh-ed25519 XXXXXXXX user@example.com' >> ~/.ssh/authorized_keys
```

> Tips:
>
> Linux 主机可以直接使用 `ssh-copy-id` 将公钥导入到远程主机，登陆参数与 `ssh` 相同