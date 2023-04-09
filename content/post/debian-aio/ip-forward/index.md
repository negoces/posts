---
title: "Debian 网关 [Episode 03]: 启用转发和 NAT"
description: "启用内核的 IPv4 和 IPv6 转发并使用 nftables 实现 NAT"
date: 2023-04-09T12:38:17+08:00
slug: b01133d3
#image: "cover.png"
tags: [Debian, Router, Gateway, nftables, NAT]
categories: Debian Router
---

## 开启 IP Forward

- 创建并编辑 `/etc/sysctl.d/10-net.conf`

```ini
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```

## Nftables NAT

- 安装 nftables (一般默认安装)

```bash
sudo apt install -y nftables
```

- 编辑 **`/etc/nftables.conf`**
- `line 10` masquerade 可选类型 `fully-random`、`random`、`persistent`

```groovy
flush ruleset

table ip nat {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        iifname "br-lan" jump ip_masquerade
    }

    chain ip_masquerade {
        oifname "eth0" masquerade fully-random
    }
}
```

- 启用: `sudo systemctl enable --now nftables`
