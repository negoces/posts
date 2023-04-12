---
title: "NAT Benchmark"
description: "利用 netns、iperf3 对 CPU NAT 性能进行测试"
date: 2023-04-12T22:38:20+08:00
slug: f37924e6
#image: "cover.png"
tags: [nftables, NAT, iproute2, netns, iperf3]
categories: Network
---

- netns (network namespace)

## 结构

```text
  [upstream]                   [router]                   [downstream]
      up-lan  <---->  rt-wan              rt-lan  <---->  down-wan
192.168.40.1          192.168.40.2  192.168.41.1          192.168.41.2
```

## 实操

### 创建命名空间

```bash
sudo ip netns add upstream
sudo ip netns add router
sudo ip netns add downstream
```

- 查看: `ip netns list`

### 创建 veth pair

```bash
sudo ip link add up-lan type veth peer rt-wan
sudo ip link add rt-lan type veth peer down-wan
```

- 查看 `ip link | grep @ -A 1`

### 将网卡绑定到 netns

```bash
sudo ip link set up-lan netns upstream
sudo ip link set rt-wan netns router
sudo ip link set rt-lan netns router
sudo ip link set down-wan netns downstream
```

- 查看:

```bash
sudo ip -n upstream link
sudo ip -n router link
sudo ip -n downstream link
```

### 设置 IP 地址

```bash
sudo ip -n upstream addr add 192.168.40.1/24 dev up-lan
sudo ip -n router addr add 192.168.40.2/24 dev rt-wan
sudo ip -n router addr add 192.168.41.1/24 dev rt-lan
sudo ip -n downstream addr add 192.168.41.2/24 dev down-wan
```

### 启动所有网卡

```bash
sudo ip -n upstream link set lo up
sudo ip -n upstream link set up-lan up

sudo ip -n router link set lo up
sudo ip -n router link set rt-wan up
sudo ip -n router link set rt-lan up

sudo ip -n downstream link set lo up
sudo ip -n downstream link set down-wan up
```

### 添加默认路由

```bash
sudo ip -n router route add default dev rt-wan
sudo ip -n downstream route add default dev down-wan via 192.168.41.1
```

### 启用 NAT

```bash
sudo ip netns exec router nft 'add table ip nat'
sudo ip netns exec router nft 'add chain ip nat postrouting { type nat hook postrouting priority srcnat; policy accept; }'
sudo ip netns exec router nft 'add rule ip nat postrouting iifname "rt-lan" oifname "rt-wan" counter masquerade fully-random'
```

- 查看规则

```bash
sudo ip netns exec router nft list ruleset
```

- 验证连通性

```bash
sudo ip netns exec downstream ping 192.168.40.1
```

### iperf3 测速

- Server

```bash
sudo ip netns exec upstream iperf3 -s
```

- Client

```bash
sudo ip netns exec downstream iperf3 -c 192.168.40.1
```

### 销毁所有命名空间

```bash
sudo ip netns del upstream
sudo ip netns del router
sudo ip netns del downstream
```
