---
title: "Debian 网关 [Episode 04]: DNS 服务 (带分流)"
description: "使用 dnsmasq 实现域名分流解析"
date: 2023-04-09T17:30:23+08:00
slug: b0021561
#image: "cover.png"
tags: [Debian, Router, Gateway, DNS, dnsmasq]
categories: Debian Router
---

## 安装 dnsmasq

```bash
sudo apt install -y dnsmasq
```

## 配置 dnsmasq

### 删除原有配置

反正本身也没啥配置

- 先关闭 dnsmasq

```bash
sudo systemctl stop dnsmasq
```

- 再删除

```bash
sudo rm -vf /etc/dnsmasq.conf
# sudo rm -vf /etc/dnsmasq.d/*
```

### 基础配置

创建并编辑 `/etc/dnsmasq.conf`

```ini
port=53
server=1.1.1.1
server=1.0.0.1
no-resolv
all-servers
cache-size=8192
conf-dir=/etc/dnsmasq.d
```

### 分流配置

**规则来源:** <https://github.com/felixonmars/dnsmasq-china-list> 

- 切换到配置目录

```bash
cd /etc/dnsmasq.d
```

- 下载配置

```bash
sudo curl -fLO "https://raw.kgithub.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf"
sudo curl -fLO "https://raw.kgithub.com/felixonmars/dnsmasq-china-list/master/apple.china.conf"
sudo curl -fLO "https://raw.kgithub.com/felixonmars/dnsmasq-china-list/master/bogus-nxdomain.china.conf"
sudo curl -fLO "https://raw.kgithub.com/felixonmars/dnsmasq-china-list/master/google.china.conf"
```

### 启动 dnsmasq

```bash
sudo systemctl start dnsmasq
```

## 解决 DNS 污染问题

### 方案一：DoH

#### 安装 cloudflared

```bash
curl -fLO "https://kgithub.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
sudo apt install ./cloudflared-linux-amd64.deb
```

#### 写入 service 文件

```bash
sudo tee /etc/systemd/system/cloudflared-proxy-dns.service > /dev/null <<EOF
[Unit]
Description=DNS over HTTPS (DoH) proxy client
Wants=network-online.target nss-lookup.target
Before=nss-lookup.target

[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
DynamicUser=yes
ExecStart=/usr/local/bin/cloudflared proxy-dns --port 5053

[Install]
WantedBy=multi-user.target
EOF
```

#### 启用 cloudflared

```bash
sudo systemctl enable --now cloudflared-proxy-dns
```

#### 修改 dnsmasq 配置

- 修改 `/etc/dnsmasq.conf`，仅保留一个 server

```bash
server=127.0.0.1#5053
```

- **随后重启 dnsmasq**

### 方案二：将 DNS 流量代理出去

dnsmasq 没有代理选项，需要用到透明代理技术，参见下一篇文章
