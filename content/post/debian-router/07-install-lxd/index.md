---
title: "Debian 网关 [Episode 07]: 安装 LXD"
description: "安装 Linux Containers (Linux 容器)"
date: 2023-04-21T12:21:08+08:00
slug: 5e230e0a
image: "cover.png"
tags: [Debian, Router, Gateway, LXC, LXD]
categories: Debian Router
---

> LXD is a next generation system container and virtual machine manager. It offers a unified user experience around full Linux systems running inside containers or virtual machines.

不是说安装 LXC 吗，怎么变成 LXD 了:

- LXD 可以理解为第二代 LXC，本质上没什么区别，只是指令和管理方式变了
- LXC 依赖 dnsmasq 且默认启用，和我们的网络配置有点小冲突
- LXD 只需要设置一次镜像，不需要每次下载都指定镜像了

## 安装 LXD

### 通过 apt 安装

```bash
sudo apt update && sudo apt install -y lxd
```

### 初始化配置

```bash
$ sudo lxd init

Would you like to use LXD clustering? (yes/no) [default=no]: no
Do you want to configure a new storage pool? (yes/no) [default=yes]: yes
Name of the new storage pool [default=default]: default
Name of the storage backend to use (dir, zfs) [default=zfs]: dir
Would you like to connect to a MAAS server? (yes/no) [default=no]: no
Would you like to create a new local network bridge? (yes/no) [default=yes]: no
Would you like to configure LXD to use an existing bridge or host interface? (yes/no) [default=no]: yes
Name of the existing bridge or host interface: br-lan
Would you like the LXD server to be available over the network? (yes/no) [default=no]: no
Would you like stale cached images to be updated automatically? (yes/no) [default=yes]: yes
Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]: no
```
- 其中:
  - `line 6` 询问是否使用 zfs，由于我们只在数据盘上创建了 zfs，在这里启用会干扰数据盘的速度
  - `line 8` 询问是否创建新的网桥
  - `line 9` 询问是加入已有网桥
  - `line 10` 询问是已有网桥名称
- 默认数据存储位置: `/var/lib/lxd/storage-pools/default`

### 设置镜像


```bash
# 任选一个
# 北外镜像
export MIRROR_URL="https://mirrors.bfsu.edu.cn/lxc-images/"
# 南京大学
export MIRROR_URL="https://mirror.nju.edu.cn/lxc-images/"

# 设置镜像
# 当前用户
lxc remote add mirror ${MIRROR_URL} --protocol=simplestreams --public
# root 用户
sudo lxc remote add mirror ${MIRROR_URL} --protocol=simplestreams --public
```

### 授权使用 lxc 命令

本质上和 Docker 一样，将用户加入到对应组内，使用户拥有 sock 的读写权限

```bash
sudo usermod -aG lxd ${USER}
```

重新登陆生效

## 基本使用方法

### 查看可用镜像

```bash
lxc image list mirror:
# with filter
lxc image list mirror: architecture=x86_64 type=container
```

### 创建并启动容器

```bash
# lxc launch <remote>:<image_name> <name> <args>
lxc launch mirror:debian/12/cloud test
```

- 默认均为非特权容器
- 与 lxc 不一样，用户间容器不隔离，统一管理
- 可通过指定参数创建特权容器
- 也可后续修改为特权容器

### 列出所有容器

```bash
lxc list
```

### 附加 | Attach

LXD 并没有提供类似 lxc-attach 的功能，但是可用这样实现:

```bash
lxc exec <name> -- /bin/bash
# 对于 Openwrt/Alpine
lxc exec <name> -- /bin/ash
```

### 停止并销毁容器

```bash
lxc stop <name>
lxc delete <name>
```

## 在 LXD 中运行 podman

### 绑定静态IP

通过 dnsmasq 实现给指定主机名设置静态IP

编辑 `/etc/dnsmasq.conf`

```bash
# dhcp-host=<IP>,<hostname>,infinite
dhcp-host=192.168.64.2,podman,infinite
```

### 创建容器

- 若要使用特权容器：在 `config:` 中追加 `security.privileged: true`

```bash
sudo lxc launch mirror:debian/12/cloud podman <<EOF
config:
  security.nesting: true
  linux.kernel_modules: ip_tables,ip6_tables,netlink_diag,nf_nat,overlay
  raw.lxc: |-
    lxc.apparmor.profile=unconfined
    lxc.mount.auto=proc:rw sys:rw cgroup:rw
    lxc.cgroup.devices.allow=a
    lxc.cap.drop=
EOF
```

### 设置容器内系统的镜像

```bash
sudo lxc exec podman -- /bin/bash

export MIRROR_URL="https://mirrors.bfsu.edu.cn"
export BRANCH="bookworm"
export COMPONENT="main contrib non-free non-free-firmware"

echo "deb ${MIRROR_URL}/debian/ ${BRANCH} ${COMPONENT}
deb ${MIRROR_URL}/debian/ ${BRANCH}-updates ${COMPONENT}
deb ${MIRROR_URL}/debian-security/ ${BRANCH}-security ${COMPONENT}" | \
tee /etc/apt/sources.list && apt update
```

### 安装 podman

```bash
apt install -y podman podman-compose
```

### 测试

```bash
podman run --rm -it alpine
```

## [笔记] k3s

### 映射 `/dev/kmsg`

```bash
echo 'L /dev/kmsg - - - - /dev/console' > /etc/tmpfiles.d/kmsg.conf
systemctl reboot
```

### 安装及运行 k3s

```bash
sudo apt install -y curl
curl -fLO "https://github.com/k3s-io/k3s/releases/latest/download/k3s"
chmod 755 k3s
sudo mv k3s /usr/local/sbin

k3s server --write-kubeconfig-mode 644
```
