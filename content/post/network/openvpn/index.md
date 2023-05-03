---
title: "OpenVPN"
description: "OpenVPN"
date: 2023-04-15T15:25:23+08:00
slug: 33a2461b
#image: "cover.png"
tags: [OpenVPN]
categories: Network
draft: true
// TODO: openvpn
---

## Install

```bash
sudo apt install openvpn
```

1. `cd /etc/openvpn`
1. PKI & CA
    ```bash
    # 初始化 PKI 目录
    sudo /usr/share/easy-rsa/easyrsa init-pki

    # 创建根 CA (不设置密码)
    sudo /usr/share/easy-rsa/easyrsa build-ca nopass

    # 创建服务器证书
    # sudo /usr/share/easy-rsa/easyrsa --days=3650 build-server-full <name> [nopass]
    sudo /usr/share/easy-rsa/easyrsa --days=3650 build-server-full server nopass

    # 创建客户端证书
    # sudo /usr/share/easy-rsa/easyrsa --days=3650 build-client-full <name> [nopass]
    sudo /usr/share/easy-rsa/easyrsa --days=3650 build-client-full test nopass
    sudo /usr/share/easy-rsa/easyrsa --days=3650 build-client-full client2 nopass

    # 创建 Diffie-Hellman
    sudo /usr/share/easy-rsa/easyrsa gen-dh
    ```