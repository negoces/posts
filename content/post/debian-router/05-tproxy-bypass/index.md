---
title: "Debian 网关 [Episode 05]: 透明代理"
description: "使用 nftables 实现不依赖代理软件分流的透明代理"
date: 2023-04-11T17:08:22+08:00
slug: fd2f28d0
image: "cover.png"
tags: [Debian, Router, Gateway, TProxy, nftables]
categories: Debian Router
---

## 先决条件

- 已配置代理程序 (clash、xray、v2ray)，且已监听 tproxy 端口
- 已安装 nftables
- 已配置 `clash.service`、`xray.service`、`v2ray.service` 中的任意一个

## 获取 CN IP 地址块

```bash
# 创建 nftables.conf.d 文件夹
sudo mkdir -p /etc/nftables.conf.d

# 获取 delegated-apnic-latest 文件，需重复使用
curl -fL "https://ftp.apnic.net/stats/apnic/delegated-apnic-latest" -o /tmp/apnic.iplist

# 写入 ipv4 地址集合
cat /tmp/apnic.iplist | \
awk -F '|' '/CN/&&/ipv4/ {print $4 "/" 32-log($5)/log(2)}' | \
sed ':label;N;s/\n/, /;b label' | sed 's/$/& }/g' | \
sed 's/^/{ &/g' | sed 's/^/define CN = /' | \
sudo tee /etc/nftables.conf.d/ip_cn.nftsets > /dev/null

# [选]删除 delegated-apnic-latest
rm /tmp/apnic.iplist
```

> **Tips:**
>
> - IPv6 规则 (在删除 delegated-apnic-latest 之前)
>
> ```bash
> # ipv6 地址集合
> cat /tmp/apnic.iplist | \
> awk -F '|' '/CN/&&/ipv6/ {print $4 "/" $5}' | \
> sed ':label;N;s/\n/, /;b label' | sed 's/$/& }/g' | \
> sed 's/^/{ &/g' | sed 's/^/define CN_V6 = /'
> ```

## 透明代理规则

### 编写规则

- 编辑 `/etc/nftables.tproxy.conf`

```groovy
table ip proxy {
    include "/etc/nftables.conf.d/ip_cn.nftsets"
    define RESERVED = { 0.0.0.0/8, 127.0.0.0/8, 169.254.0.0/16, 10.0.0.0/8, 100.64.0.0/10, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 255.255.255.255/32 }
    define PROXY_PORT = 5092
    define REROUTE_MARK = 0xe105

    set whitelist {
        type ipv4_addr
    }

    chain prerouting {
        type filter hook prerouting priority mangle; policy accept;
        iifname { "br-lan" } ip daddr != $RESERVED jump proxy_rule
    }

    chain proxy_rule {
        ip daddr @whitelist return
        tcp dport { 22, 80, 443, 853 } jump proxy_redirect
        udp dport { 53, 443 } jump proxy_redirect
    }

    chain proxy_redirect {
        ip daddr $CN return
        ip protocol tcp tproxy to :$PROXY_PORT meta mark set $REROUTE_MARK
        ip protocol udp tproxy to :$PROXY_PORT meta mark set $REROUTE_MARK
    }
}
```

### dnsmasq 白名单

将某些域名的 ip 加入白名单，不然会因为代理而无法登陆，比如 Arcaea

```bash
# /etc/dnsmasq.d/nftset.conf
nftset=/arcapi-v2.lowiro.com/4#ip#proxy#whitelist
nftset=/arcapi-pro-tcp-lb-059cb924e42f3fb8.elb.us-west-2.amazonaws.com/4#ip#proxy#whitelist
```

### 如何 Debug

- 在需要 debug 的地方加上规则 `meta nftrace set 1`
- 执行 `sudo nft monitor trace`

### tproxy.service

- 将 `line 5,6` 的 `clash.service` 换成对应代理软件

```systemd
# /etc/systemd/system/tproxy.service
[Unit]
Description= Nftables TProxy
Documentation= https://www.netfilter.org/projects/nftables/manpage.html
Requires=clash.service
After=clash.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPost=ip rule add fwmark 0xe105 table 105
ExecStartPost=ip route add local default dev lo table 105
ExecStart=nft -f /etc/nftables.tproxy.conf
ExecStop=nft delete table ip proxy
ExecStopPost=ip route del local default dev lo table 105
ExecStopPost=ip rule del fwmark 0xe105 table 105

[Install]
WantedBy=multi-user.target
```

- 启用

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now tproxy
```

## [选] 代理本机流量

- 有些场景需要代理本机的流量，比如：将本地的部分 DNS 流量代理出去
- 将以下规则添加进上面的配置
- 注意：将上面的 `line 9` 改为下面的 `line 20`

```groovy
table ip proxy {
    define LOCAL_PROXY_RULE = { 1.1.1.1, 1.0.0.1, 8.8.8.8, 8.8.4.4 }

    chain output {
        type route hook output priority mangle; policy accept;
        ip daddr $LOCAL_PROXY_RULE jump output_proxy_rule
    }

    chain output_proxy_rule {
        tcp dport { 853 } jump output_reroute_mark
        udp dport { 53 } jump output_reroute_mark
    }

    chain output_reroute_mark {
        meta mark set $REROUTE_MARK
    }

    chain prerouting {
        type filter hook prerouting priority mangle; policy accept;
        iifname { "lo", "br-lan" } ip daddr != $RESERVED jump proxy_rule
    }
}
```
