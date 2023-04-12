---
title: "Debian 安装及配置 Clash"
description: "在 Debian 上下载及安装 CLash"
date: 2023-04-12T10:03:24+08:00
slug: 1b91e610
#image: "cover.png"
tags: [Debian, TProxy, Proxy, Clash]
categories: Network
---

## 下载 Clash

```bash
export CLASH_VER="v1.14.0" # Clash 版本
export CLASH_ARCH="amd64" # Clash 架构
export CLASH_NAME="clash-linux-${CLASH_ARCH}-${CLASH_VER}"

# 安装必要工具
sudo apt install -y tar gzip xz-utils curl

mkdir -p /tmp/clash-tmp
cd /tmp/clash-tmp

# 下载及解压 Clash
curl -fLO "https://kgithub.com/Dreamacro/clash/releases/download/${CLASH_VER}/${CLASH_NAME}.gz" && \
gunzip ${CLASH_NAME}.gz

# 下载及解压 yacd 面板
curl -fLO "https://kgithub.com/haishanh/yacd/releases/latest/download/yacd.tar.xz" && \
tar -xJf yacd.tar.xz

# 下载 Country.mmdb
curl -fLO "https://kgithub.com/xOS/Country.mmdb/releases/latest/download/Country.mmdb"

# 将所有文件复制到 /opt/clash
sudo mkdir -p /opt/clash
sudo mv ${CLASH_NAME} /opt/clash
sudo mv public /opt/clash
sudo mv Country.mmdb /opt/clash
sudo ln -s -T /opt/clash/${CLASH_NAME} /opt/clash/clash
sudo chmod 755 /opt/clash/clash*
sudo mkdir -p /opt/clash/subconf
sudo chmod 777 /opt/clash/subconf
```

## 配置 Clash

### 单机场示例

- 编辑 `/opt/clash/config.yaml`

```yaml
port: 8080
socks-port: 1080
tproxy-port: 5092

allow-lan: true
bind-address: "*"
mode: rule
log-level: warning
ipv6: false
external-controller: 0.0.0.0:5090
external-ui: ./public

proxy-groups:
  - name: "Select"
    type: select
    use:
      - proxies

proxy-providers:
  proxies:
    type: http
    path: ./subconf/proxies.yaml
    # 订阅地址
    url:  https://url/config.yaml
    interval: 3600
    health-check:
      enable: true
      url: http://www.google.com/generate_204
      interval: 1800

rules:
  - MATCH, Global
```

### 多机场示例

```yaml
port: 8080
socks-port: 1080
tproxy-port: 5092

allow-lan: true
bind-address: "*"
mode: rule
log-level: warning
ipv6: false
external-controller: 0.0.0.0:5090
external-ui: ./public

proxy-groups:
  - name: "Providers"
    type: select
    proxies:
      - ProviderA
      - ProviderB
  - name: "ProviderA"
    type: select
    use:
      - providera
  - name: "ProviderB"
    type: select
    use:
      - providerb

proxy-providers:
  providera:
    type: http
    path: ./subconf/providera.yaml
    url: https://providera
    interval: 3600
    health-check:
      enable: true
      url: http://www.google.com/generate_204
      interval: 1800
  providerb:
    type: http
    path: ./subconf/providerb.yaml
    url: https://providerb
    interval: 3600
    health-check:
      enable: true
      url: http://www.google.com/generate_204
      interval: 1800

rules:
  - MATCH, Providers
```

### 试运行

```bash
sudo /opt/clash/clash -d /opt/clash
```

## clash.service

### 配置

```systemd
# /etc/systemd/system/clash.service
[Unit]
Description=clash
Documentation=man:clash
After=network.target network-online.target nss-lookup.target

[Service]
Type=simple
AmbientCapabilities=CAP_NET_RAW
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/opt/clash/clash -d /opt/clash
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=7s

[Install]
WantedBy=multi-user.target
```

### 启用

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now clash
```
