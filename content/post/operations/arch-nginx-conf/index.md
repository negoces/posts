---
title: "Arch Linux 上的 Nginx 配置"
description: "让 Nginx 的配置在 Arch Linux 更有序更易读"
date: 2023-03-14T16:57:44+08:00
slug: 503a8410
#image: "cover.png"
tags: ["Arch Linux", Nginx, Web]
categories: Operations
---

在 Arch Linux 上安装的 Nginx 默认将配置全部塞进了 `/etc/nginx/nginx.conf`，有时候想修改某一个站点的配置时要翻半天

## 创建分类文件夹

```bash
# 创建全局配置文件夹，比如 hash_size 配置
sudo mkdir -p /etc/nginx/conf.d
# 创建可复用配置文件夹，比如通配证书设置
sudo mkdir -p /etc/nginx/tmpl.d
# 创建站点配置文件夹
sudo mkdir -p /etc/nginx/sites.d
```

## 在主配置文件中包含文件夹

修改 `/etc/nginx/nginx.conf`


```nginx
...;

http {
    ...;

    include conf.d/*.conf;
    include sites.d/*.conf;
}
```

## 部分实用配置

### `conf.d/hash_size.conf`

如果不设置的话 `nginx -t` 的时候会有 warning

```nginx
types_hash_max_size 4096;
types_hash_bucket_size 64;
client_max_body_size 0;
```

### `conf.d/http_to_https.conf`

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location / {
        return 301 https://$host$request_uri;
    }
}
```

### `tmpl.d/tls_example.com.conf`

可复用的通配域名配置

```nginx
ssl_certificate /usr/share/lego/certificates/_.example.com.crt;
ssl_certificate_key /usr/share/lego/certificates/_.example.com.key;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
ssl_session_tickets off;
ssl_dhparam /usr/share/lego/certificates/dhparam;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
add_header Strict-Transport-Security "max-age=63072000" always;
```

生成 `dhparam`:

```bash
sudo openssl dhparam -out /usr/share/lego/certificates/dhparam 2048
sudo chmod 644 /usr/share/lego/certificates/dhparam
```

使用:

```nginx
server {
    include tmpl.d/tls_example.com.conf;
}
```

### 反向代理 Websocket

```nginx
location /ws/ {
        proxy_pass http://127.0.0.1:5090;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
}
```

### 同端口下 http 跳转到 https


```nginx
server {
    listen 51443 http2 ssl;
    listen [::]:51443 http2 ssl;
    server_name _;

    error_page 497 301 =307 https://$host:$server_port$request_uri;

    include tmpl.d/tls_example.com.conf;
}
```