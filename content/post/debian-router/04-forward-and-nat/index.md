---
title: "Debian 网关 [Episode 04]: 启用转发和 NAT"
description: "启用内核的 IPv4 和 IPv6 转发并使用 nftables 实现 NAT"
date: 2023-04-09T18:38:17+08:00
slug: b01133d3
image: "cover.png"
tags: [Debian, Router, Gateway, nftables, NAT, Firewall]
categories: Debian Router
---

## 开启 IP Forward

- 创建并编辑 `/etc/sysctl.d/10-net.conf`
- 规则重启生效
- 若要立即生效: `sudo sysctl -p /etc/sysctl.d/10-net.conf`

```ini
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```

## Nftables

### 安装 nftables

- **Debian 默认安装**，若未安装使用以下指令安装：

```bash
sudo apt install -y nftables
```

### NAT

- 编辑 **`/etc/nftables.conf`**
- `line 10` masquerade 可选类型 `fully-random`、`random`、`persistent`
- 将为来自 `br-lan` 路由至 `eth0`、`ppp*` 的启用 NAT

```groovy
flush ruleset

table ip nat {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        iifname "br-lan" jump ip_masquerade
    }

    chain ip_masquerade {
        oifname "eth0" masquerade fully-random
        oifname "ppp*" masquerade fully-random
    }
}
```

### 防火墙

- 在 `/etc/nftables.conf` 文件中追加
- 将丢弃所有来自 `eth0`、`ppp*` 的包 (丢弃远程主动建立连接的包，已建立的连接将正常放行，否则无法正常上网)

```groovy
table inet filter {
    chain input {
        type filter hook input priority filter; policy accept;
        iifname "eth0" jump firewall
        iifname "ppp*" jump firewall
    }

    chain firewall {
        ct state established,related accept
        ct state invalid drop
        ct state new drop
    }
}
```

### 启用

- 开机自启:
    ```bash
    sudo systemctl enable --now nftables
    ```
- 使修改生效:
    ```bash
    sudo systemctl restart nftables
    ```
    - 或者
    ```bash
    sudo nft -f /etc/nftables.conf
    ```
