---
title: "使用 LEGO 和 SystemD 自动续签证书"
description: "像我这种懒人怎么可能每3个月去手动续签一次"
date: 2023-03-14T13:47:43+08:00
slug: cb8a62ff
image: "cover.png"
tags: [letsencrypt, acme, certificate, go-acme]
categories: Operations
---

网络上大部分教程用的是 `crontab` 和 `acme.sh`, acme.sh 我不知道怎么样，但是 systemd 和 crontab 相比，可以查看执行计划和执行日志, lego 是使用 Golang 编写的单文件 acme 客户端，多平台，开箱即用，支持多种域名服务商

## 安装 lego

对于 Arch Linux:

```bash
sudo pacman -Sy lego
```

对于其他发行版: 前往 <https://github.com/go-acme/lego/releases/latest/> 下载

## 获取 AccessKey (以 Aliyun 为例)

1. 前往 **RAM访问控制(<https://ram.console.aliyun.com/users>)**
1. 点击 **创建用户**，登录名称和显示名称任意，**访问控制中勾选 OpenAPI 调用访问**
1. 立即保存 `AccessKey ID` 和 `AccessKey Secret` (只会显示一次，以后无法查看)
1. 前往 **[权限管理/授权](https://ram.console.aliyun.com/permissions)**
1. 点击 **新增授权**，`授权主体` 为刚刚创建的账号，`选择权限`选择 `系统策略` 里的 `AliyunDNSFullAccess`，点击确定

**Tips: `AccessKey ID` 和 `AccessKey Secret` 要严格保密，以防泄露**

## 签发证书

> 其他服务商配置请参考: <https://go-acme.github.io/lego/dns/>

1. 创建证书存储文件夹:

    ```bash
    sudo mkdir -p /usr/share/lego
    ```

1. 申请证书

    - `line 2-3` 填写 `AccessKey`
    - `line 5` 替换成自己的邮箱
    - `line 9` 替换成自己的域名

    ```bash
    sudo LEGO_PATH=/usr/share/lego \
    ALICLOUD_ACCESS_KEY=<AccessKey ID> \
    ALICLOUD_SECRET_KEY=<AccessKey Secret> \
    /usr/bin/lego --accept-tos \
      --email user@example.com \
      --dns alidns \
      # 如果要申请通配符证书，取消下行注释 \
      #-d "*.example.com" \
      -d "example.com" run
    ```

1. 给予可访问权限

    ```bash
    sudo chmod 755 /usr/share/lego/certificates
    sudo chmod 644 /usr/share/lego/certificates/*
    ```

1. 查看证书信息:

    ```bash
    sudo cat /usr/share/lego/certificates/_.example.com.crt | \
    openssl x509 -noout -text
    ```

## 创建续签脚本

1. 编辑 `/usr/share/lego/renew.sh`

    - `line 3-4` 填写 `AccessKey`
    - `line 6` 替换成自己的邮箱
    - `line 9` 替换成自己的域名

    ```bash
    #!/bin/bash
    LEGO_PATH=/usr/share/lego \
    ALICLOUD_ACCESS_KEY=<AccessKey ID> \
    ALICLOUD_SECRET_KEY=<AccessKey Secret> \
    /usr/bin/lego --accept-tos \
      --email user@example.com \
      --dns alidns \
      #-d "*.example.com" \
      -d "example.com" renew
    
    # 如果有同账号下的多个域名可追加以下内容，不同账号请创建新文件
    /usr/bin/lego --accept-tos \
      --email user@example.com \
      --dns alidns \
      -d "example2.com" renew
    
    # 如果要顺便让 Nginx 重载证书:
    nginx -s reload
    ```

    > Tips: 此脚本无论续签是否成功都会重载 Nginx，官方提供了 `--renew-hook="./myscript.sh"` 参数可在仅成功时运行，但是需要单独写一个脚本，下面是示例：
    >
    > 1. 编辑 `/usr/share/lego/hook.sh`
    >
    >     ```bash
    >     #!/bin/bash
    >     nginx -s reload
    >     ```
    >
    > 1. 修改权限
    >
    >     ```bash
    >     sudo chmod 700 /usr/share/lego/hook.sh
    >     ```
    >
    > 1. 编辑 `/usr/share/lego/renew.sh` 的 `line 9`
    >
    >     ```bash
    >       -d "example.com" renew --renew-hook="/usr/share/lego/hook.sh"
    >     ```
    >

1. 修改权限，防止 `AccessKey` 泄露

    ```bash
    sudo chmod 700 /usr/share/lego/renew.sh
    ```

1. 运行测试

    ```bash
    sudo /usr/share/lego/renew.sh
    ```

## 编写 service/timer 文件

### service 文件

- 编辑 `/etc/systemd/system/task-lego-renew.service`

```ini
[Unit]
Description=Lego Renew

[Service]
ExecStart=/usr/share/lego/renew.sh
```

### timer

- 编辑 `/etc/systemd/system/task-lego-renew.timer`
- `line 5` 含义：将在每周日凌晨 04:00 运行

```ini
[Unit]
Description=Timer - Lego Renew

[Timer]
OnCalendar=Sun *-*-* 04:00:00
Unit=task-lego-renew.service

[Install]
WantedBy=timers.target
```

### 启动

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now task-lego-renew.timer
```

### 任务计划查询查询

```bash
systemctl status task-lego-renew.timer
```

### 日志查询

```bash
journalctl -e -u task-lego-renew
```
