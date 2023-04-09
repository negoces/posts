---
title: "Debian 网关 [Episode 04]: DNS 服务 (带分流)"
description: "使用 Unbound 实现域名分流解析"
date: 2023-04-09T17:30:23+08:00
slug: b0021561
#image: "cover.png"
tags: [Debian, Router, Gateway, DNS, Unbound]
categories: Debian Router
---

## 安装 Unbound

```bash
sudo apt install -y unbound
```

## 配置 Unbound

### 删除原有配置

反正本身也没啥配置

```bash
sudo rm -vf /etc/unbound/unbound.conf
sudo rm -vf /etc/unbound/unbound.conf.d/*
```

### 基础配置

- 创建并编辑 `/etc/unbound/unbound.conf`

```yaml
include-toplevel: "/etc/unbound/unbound.conf.d/*.conf"

# 本机 CLI 控制
remote-control:
  control-enable: yes
  control-use-cert: no
  control-interface: /run/unbound.ctl

server:
  log-queries: no
  use-syslog: no
  verbosity: 1
  tls-system-cert: yes

  port: 53
  interface: 0.0.0.0
  interface: ::
  access-control: 0.0.0.0/0 allow
  access-control: ::/0 allow

forward-zone:
  name: "."
  forward-addr: 1.1.1.1
  forward-addr: 1.0.0.1
```

### 分流配置

> **分流规则列表**
>
> **规则来源:** <https://github.com/felixonmars/dnsmasq-china-list>  
> **生成时间:** 2023/04/09
>
> - [accelerated-domains.china.unbound.conf (4.3MB)](accelerated-domains.china.unbound.conf)
> - [apple.china.unbound.conf (12KB)](apple.china.unbound.conf)
> - [google.china.unbound.conf (13KB)](google.china.unbound.conf)


将以上文件下载至 `/etc/unbound/unbound.conf.d`

### 自定义解析记录

- 直接在 `/etc/unbound/unbound.conf` 中追加
- 或者创建并编辑 `/etc/unbound/unbound.conf.d/custom.conf`

```yaml
server:
  local-data: "router.local A 192.168.64.1"
```

### 启动及开机自启

```bash
sudo systemctl enable --now unbound
```

### CLI 控制

```bash
sudo /usr/sbin/unbound-control <command>
# eg:
sudo /usr/sbin/unbound-control reload
sudo /usr/sbin/unbound-control list_forwards
sudo /usr/sbin/unbound-control list_local_data
```
