---
title: "Debian 网关 [Episode 07]: 安装 LXC"
description: "安装 Linux Containers (Linux 容器)"
date: 2023-04-19T15:15:08+08:00
slug: 5e230e0a
#image: "cover.png"
tags: [Debian, Router, Gateway, LXC]
categories: Debian Router
---

~~执行 `sudo apt install -y lxc`，结束！~~

为什么安装完不能直接用:

- Debian 安装软件时默认启用服务，lxc-net 与 dnsmasq
- lxc 会调用 lxc-net，依旧冲突

## 安装 LXC

```bash
sudo apt install -y lxc
```

## 禁用 lxc-net

```bash
sudo systemctl disable --now lxc-net
```

## 修改 lxc.service

```bash
sudo systemctl edit --full lxc
```

修改为:

```diff
- After=network.target remote-fs.target lxc-net.service
- Wants=lxc-net.service
+ After=network.target remote-fs.target
+ # Wants=lxc-net.service
```

重载配置:

```bash
sudo systemctl daemon-reload
```

Tips: 恢复默认配置: `sudo systemctl revert lxc`

## [其他] 使用指南

### 修改创建容器的默认配置

- 新建容器默认加入 br-lan 网桥
- 已开启容器嵌套

```ini
# /etc/lxc/default.conf
lxc.net.0.type = veth
lxc.net.0.link = br-lan
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx

lxc.apparmor.profile = generated
lxc.apparmor.allow_nesting = 1
lxc.include = /usr/share/lxc/config/nesting.conf
```

### 容器操作 (创建、启动、附加、停止、销毁)

```bash
# 创建
sudo lxc-create -t download -n <name> -- --server mirrors.bfsu.edu.cn/lxc-images

sudo lxc-create -t download -n a2 -- \
  --server mirrors.bfsu.edu.cn/lxc-images \
  --dist alpine \
  --release edge \
  --arch amd64

sed -i 's/dl-cdn.alpinelinux.org/mirrors.bfsu.edu.cn/g' /etc/apk/repositories

# 启动
sudo lxc-start <name>
# 附加
sudo lxc-attach <name>
# 停止
sudo lxc-stop <name>
# 销毁
sudo lxc-destroy <name>
```

```ini
# Template used to create this container: /usr/share/lxc/templates/lxc-download
# Parameters passed to the template: --server mirrors.bfsu.edu.cn/lxc-images
# Template script checksum (SHA-1): 7067b9ffb52b0c1514c5e6773b18b8ed134072b5
# For additional config options, please look at lxc.container.conf(5)

# Uncomment the following line to support nesting containers:
#lxc.include = /usr/share/lxc/config/nesting.conf
# (Be aware this has security implications)


# Distribution configuration
lxc.include = /usr/share/lxc/config/common.conf
lxc.arch = linux64

# Container specific configuration
lxc.rootfs.path = dir:/var/lib/lxc/nat/rootfs
lxc.uts.name = nat

# Network configuration
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:86:86:7e


lxc.mount.auto = cgroup:mixed proc:mixed sys:mixed

# /usr/share/lxc/config/nesting.conf
# Use a profile which allows nesting
lxc.apparmor.profile = lxc-container-default-with-nesting

# Add uncovered mounts of proc and sys, else unprivileged users
# cannot remount those

lxc.mount.entry = proc dev/.lxc/proc proc create=dir,optional 0 0
lxc.mount.entry = sys dev/.lxc/sys sysfs create=dir,optional 0 0
```

## 嵌套

```bash
export CT_NAME="deb"
sudo lxc-create -t download -n ${CT_NAME} \
  --userns-path /var/lib/lxc/${CT_NAME}/ns -- \
  --server mirrors.bfsu.edu.cn/lxc-images \
  --dist alpine \
  --release edge \
  --arch amd64
```