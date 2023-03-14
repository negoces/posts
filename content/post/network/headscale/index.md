---
title: "HeadScale 异地组网"
description: "n2n 搭建失败，就来用 HeadScale 了"
date: 2023-03-14T19:40:05+08:00
slug: 463373ba
image: "cover.png"
tags: [Network, HeadScale, WireGuard, "异地组网", p2p, VPN]
categories: Network
---

既然看见标题点进来了，那么应该知道异地组网是啥，就不多赘述了

**注：为了方便部署，采用 Podman 部署**

## 部署 HeadScale

1. 创建配置文件夹 `sudo mkdir -p /opt/headscale`
1. 创建空数据库 `sudo touch /opt/headscale/db.sqlite`
1. 编辑 `sudo vim /opt/headscale/config.yaml`

    ```yaml
    # 服务器 URL，应当为正在使用的域名
    server_url: https://example.com:51443

    # / 和 /metrics 的监听端口
    listen_addr: 0.0.0.0:7200
    metrics_listen_addr: 0.0.0.0:7300

    # 握手证书，如果没有，将自动生成
    private_key_path: /etc/headscale/private.key

    # TS2021 Noise protocol
    noise:
      private_key_path: /etc/headscale/noise_private.key

    # 分配的 IP 前缀
    ip_prefixes:
      - fda8::/64
      - 10.128.0.0/24

    # derp 中继服务
    derp:
      server:
        # 内置中继服务开关，如果开启 server_url 必须是 https，DERP 依赖 TLS
        enabled: true

        # 区域信息
        region_id: 999
        region_code: "headscale"
        region_name: "Headscale Embedded DERP"

        # STUN 服务监听端口
        stun_listen_addr: "0.0.0.0:3478"

      # 外部 DERP 服务器列表
      urls: []
      # 本地服务器列表(填写 YAML 路径)
      paths: []
      # 自动更新与更新间隔
      auto_update_enabled: true
      update_frequency: 24h

    # 禁用检查更新
    disable_check_updates: true
    # 不活跃节点删除间隔
    ephemeral_node_inactivity_timeout: 30m
    # 结点状态检查间隔
    node_update_check_interval: 10s

    # 数据库设置
    db_type: sqlite3
    db_path: /etc/headscale/db.sqlite

    # TLS 证书路径
    tls_cert_path: ""
    tls_key_path: ""

    log:
      # Output formatting for logs: text or json
      format: text
      level: info

    # CLI Socket
    unix_socket: /etc/headscale/headscale.sock
    unix_socket_permission: "0777"
    ```

1. 部署

    ```bash
    sudo podman run -d \
      --name headscale \
      -v /opt/headscale:/etc/headscale \
      -p 127.0.0.1:7200:7200 \
      -p 127.0.0.1:7300:7300 \
      -p 3478:3478/udp \
      --restart always \
      docker.nju.edu.cn/headscale/headscale:latest \
      headscale serve
    ```

1. 查看状态

   ```bash
   sudo podman ps -a
   ```

1. 开机自启

    ```bash
    sudo systemctl enable --now podman-restart.service
    ```

1. 测试

    ```bash
    curl http://127.0.0.1:7300/metrics
    ```

> **Tips:**
>
> 需放行端口 `3478/UDP`

## 反向代理

```nginx
map $http_upgrade $connection_upgrade {
    default      keep-alive;
    'websocket'  upgrade;
    ''           close;
}

server {
    listen 51443 http2 ssl;
    listen [::]:51443 http2 ssl;
    server_name example.com;

    error_page 497 301 =307 https://$host:$server_port$request_uri;
    include tmpl.d/tls_example.com.conf;

    location / {
        proxy_pass http://127.0.0.1:7200;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $server_name;
        proxy_redirect http:// https://;
        proxy_buffering off;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
        add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
    }
}
```

## 加入网络

- client:

```bash
# 安装
sudo pacman -Sy tailscale
# 启动
sudo systemctl enable --now tailscaled.service
# 加入
sudo tailscale up \
  --login-server=<url> \
  --accept-dns=false \
  --accept-routes \
  --netfilter-mode=off
```

- server:

```bash
# 注册用户
sudo podman exec headscale \
headscale users create <user>
# 注册节点
sudo podman exec headscale \
headscale --user <user> nodes register --key <MACHINE_KEY>
```

- 客户端连接信息查看

```bash
# 使用的 DERP 中继服务器
sudo tailscale netcheck
```

> **未完待续......**
>
> 比如访问子网，或者指定节点作为出口
