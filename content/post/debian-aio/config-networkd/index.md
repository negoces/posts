---
title: "Debian 网关 [Episode 02]: 配置网络接口"
description: "使用 systemd-networkd 配置网络接口"
date: 2023-04-05T11:24:03+08:00
slug: b04fa8dd
#image: "cover.png"
tags: [Debian, Router, Gateway, SystemD, networkd]
categories: Debian Router
---

{{<hint info>}}
**当前阶段:**

实现基本功能，拨号及 IPv6 待补充
{{</hint>}}

## 结构

![net_arch](net_arch.svg)

## 配置

- **Tips:**
    - `*.link`、`*.netdev` 配置需要重启生效
    - 对于未配置的接口，使用 `sudo networkctl reload` 进行配置
    - 对于已配置的接口，使用 `sudo networkctl reconfigure <name>` 进行重新配置
    - 建议:
        - `*.link` 使用 `00-` 前缀
        - `*.netdev` 使用 `10-` 前缀
        - `*.network` 使用 `20-` 前缀
        - 具体视情况而定

### [选] 接口改名及修改 MAC

- 例: 将 MAC 为 `00:15:5d:01:78:01` 的接口改名为 `enp1` 并将 MAC 修改为 `00:15:5d:01:00:01`
- 创建并编辑 `/etc/systemd/network/00-enp1.link`

```ini
[Match]
MACAddress=00:15:5d:01:78:01

[Link]
Name=enp1
MACAddress=00:15:5d:01:00:01
```

### WAN 口启用 DHCP 获取 IP

- 无论是 `动态IP` 上网，亦或者是 `PPPoE拨号`，都建议开启 DHCP，**以便于访问光猫或上游设备**
- 以 `eth0` 为例
- 创建并编辑 `/etc/systemd/network/20-eth0.network`

```ini
[Match]
Name=eth0

[Network]
DHCP=yes
```

### 创建 br-lan 网桥

#### 创建网桥设备

- 创建并编辑 `/etc/systemd/network/10-br-lan.netdev`
- `MACAddress` 为可选项

```ini
[NetDev]
Name=br-lan
Kind=bridge
MACAddress=00:e2:69:75:f0:06
```

#### 设置 LAN 侧 IP

- 创建并编辑 `/etc/systemd/network/20-br-lan.network`

```ini
[Match]
Name=br-lan

[Link]
RequiredForOnline=no
ActivationPolicy=always-up
ARP=yes

[Network]
Address=192.168.64.1/24
ConfigureWithoutCarrier=yes
```

#### 将物理网口绑定到网桥

- 创建并编辑 `/etc/systemd/network/20-br-lan-bind.network`

```ini
[Match]
Name=eth1
Name=eth2
Name=eth3

[Network]
Bridge=br-lan
```

**至此，可将 `/etc/systemd/network/01-dhcp.network` 安全的删除**