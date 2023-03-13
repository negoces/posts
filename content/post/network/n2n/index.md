---
title: "部署 n2n 实现异地组网"
description: "通过 n2n 访问异地内网资源"
date: 2023-03-13T17:36:12+08:00
slug: 7fe3bfed
#image: "cover.png"
tags: [Network, n2n, p2p, VPN]
categories: Network
---

## Why?

- 最开始用的 WireGuard，但是每新加设备就得修改配置添加密钥对，并且对于用 ddns 的动态 IP 服务器不太友好(只会在启动时解析域名，假如服务器 IP 发生变动，客户端将永久断连，除非重启客户端)
- 后来看到 [NetMaker](https://github.com/gravitl/netmaker)，结果也就只是看看
- 然后看到了 TailScale 和 [HeadScale](https://github.com/juanfont/headscale)，也使用了一段时间(后期会补一篇博客)，还挺好用，就是设备加入有点繁琐
- 这次看到了 [n2n](https://github.com/ntop/n2n)，来试一试

## 和 HeadScale 的区别

共同特性:

- 均支持 P2P 且支持回退到中继模式
- 均支持命名空间隔离网络

{{< columns >}}

n2n:

- 支持 supernode 之间建立连接以扩展网络
- 支持在接口上运行 DHCP 服务器
- 可选择是否加密

<--->

HeadScale:

- TailScale 的第三方自建服务端
- 底层基于 WireGuard
- 需要服务端授权或者提前签发ID才能加入网络
- 支持用户在线状态的查看与管理

{{< /columns >}}

## 架构

- `supernode` 为服务器节点，但服务器本身不在网络内
- `edge` 为客户端节点，会创建 tap 虚拟网口接入网络

```goat
    +-----+                                                         +-----+    
    |edge |<----+                                             +---->|edge |    
    +-----+     |                                             |     +-----+    
                |                                             |        ^       
              relay                                           |       p2p      
                |                                             |        v       
    +-----+     |     +----------+           +----------+     |     +-----+    
    |edge |<----+---->|super node|<--------->|super node|<----+---->|edge |    
    +-----+     |     +----------+           +----------+     |     +-----+    
       ^        |                                             |        ^       
      p2p       |                                             |       p2p      
       v        |                                             |        v       
    +-----+     |                                             |     +-----+    
    |edge |<----+                                             +---->|edge |    
    +-----+                                                         +-----+    
```

## 安装

无论服务端还是客户端，都需要安装 `n2n` 包

```bash
# Arch Linux
sudo pacman -Sy n2n

# Debian (版本较低，建议手动安装)
sudo apt update && sudo apt install -y n2n
```

最新 deb/rpm 安装包: <https://github.com/ntop/n2n/releases/latest/>

## 服务器配置

编辑 `/etc/n2n/supernode.conf`:

```ini
-p=7654
-t=5645
-F=<federation_name>
# 如果需要扩展网络，添加:
#-l=<另一超级节点的IP>:<另一超级节点的端口>
# 如果需要修改子网网段，默认 10.128.255.0-10.255.255.0/24
#-a=192.168.0.0-192.168.255.0/24
```

- 启动: `sudo systemctl enable --now supernode.service`
- 查看服务器状态: `netcat -u localhost 5645`，每 `ENTER` 一次刷新一次

Tips:

- 需放行 `7654/TCP`、`7654/UDP` 端口
- Docker/Podman 部署参考 <https://hub.docker.com/r/supermock/supernode>

## 客户端配置

编辑 `/etc/n2n/edge.conf`:

```ini
-c=<community_name>
-l=<server_address>:<server_port>
-k=<encrypt_passwd>
-A4
-a=10.128.0.2
-d=vlan0
```

- 启动: `sudo systemctl enable --now edge.service`

Tips: 如果要加入多个网络:

- 编辑 `/etc/n2n/edge-name.conf`
- 启动: `sudo systemctl enable --now edge@name.service`

## 更多配置文件示例

### 防止别人蹭你的 supernode

#### 方案一: 限制 community_name

- 编辑 `/etc/n2n/community.list`:

  ```ini
  # community_name subnet
  # 例如
  net 10.128.0.0/24
  ```

- 在 `supernode.conf` 配置文件中启用

  ```ini
  -p=7654
  -t=5645
  -F=<federation_name>
  -c=/etc/n2n/community.list
  ```

- 在客户端使用 `-c=net` 加入网络

  ```ini
  -c=net
  -l=<server_address>:<server_port>
  -k=<encrypt_passwd>
  -A4
  -a=10.128.0.2
  -d=vlan0
  ```

- 如何重载 `community.list`:

  1. `netcat -u localhost 5645`
  2. 发送 `reload_communities`

#### 方案二: 密码验证

官方文档给的方案无法使用，还在探索

- 排查后发现原因出在 Header 加密，但未发现解决方案

## 其他

更多功能还在探索，比如中继 IPv6

**注：因密码问题尚未解决，且官方未提供 Windows 客户端，大概率不会继续使用了**
