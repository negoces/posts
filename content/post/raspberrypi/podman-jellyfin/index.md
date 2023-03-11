---
title: "Jellyfin on RaspberryPi"
description: "在树莓派上通过 Podman 搭建 Jellyfin 影音库"
date: 2023-03-11T19:16:30+08:00
slug: 5f672d2a
image: "cover.png"
tags: [RaspberryPi, Podman, Jellyfin]
categories: RaspberryPi
---

## 为什么用 Podman

- 搭建容易，升级简单，迁移方便
- Docker 和 TProxy 冲突
- **零修改享用硬件加速**，二进制安装需要替换 ffmpeg 参考: [jellyfin.org/docs](https://jellyfin.org/docs/general/administration/hardware-acceleration#hardware-acceleration-on-raspberry-pi-3-and-4)

~~设备上没有跑 TProxy 的还是建议用 Docker，Podman 没有 Daemon，需要使用 SystemD 做容器自启~~  
现在 `podman-restart.service` 会在开机时自动启动所有策略为 `always` 的容器

## 安装 Podman

> **注意:**
>
> 由于我提前开启了 cgroup_memory 功能，不知道此功能是否必须，若出现问题可尝试开启，开启方法:
>
> 在 `/boot/cmdline.txt` 文件中追加 `cgroup_memory=1 cgroup_enable=memory` 内核参数，然后重启

安装的事情无脑交给包管理器就行了:

*Tips: 能交给包管理器的事情就不要自己做，除非自己有足够的能力，不然炸了都不好找人问*

```bash
sudo apt update && sudo apt -y install podman
```

*Tips: 以下服务将会自动启动*

- `podman-auto-update.timer` 每天更新容器
- `podman-restart.service` 开机自动启动所有策略为 `always` 的容器
- `podman.service`、`podman.socket` Podman 基础服务

验证安装:

```bash
sudo podman system info
```

## 安装 Jellyfin

说明:

- `line 3,4` 用户 ID，防止和宿主机产生权限冲突，可用 `id ${USER}` 查看后修改
- `line 5` 时区，参考: [WikiPedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)
- `line 6` 【可选】 被客户端发现后回应的服务器地址，与 `line 9` 有关
- `line 7` HTTP 服务端口
- `line 8` 【可选】 HTTPS 服务端口，需要证书，建议关闭后反代
- `line 9` 【可选】 服务发现端口，开启后允许被就局域网设备发现
- `line 10` 【可选】 DLNA 服务发现端口，开启后允许被就局域网设备发现
- `line 11-13` 挂载选项，一律改 `:` 前的内容，为宿主机路径，**需要提前创建文件夹**
- `line 11` 配置文件夹，**据描述：增长十分快，建议 50GB+**
- `line 12-13` 可以只挂载一个文件夹 `-v /path/to/media:/data/media`
- `line 12` 电视剧文件夹
- `line 13` 影文件夹
- `line 14-16` V4L2 硬件加速所需的设备挂载 **树莓派专用，其他设备参考: [hub.docker.com](https://hub.docker.com/r/linuxserver/jellyfin)**
- `line 18` 镜像来源，如果下载过慢可将 `lscr.io` 替换为 `docker.nju.edu.cn`

```bash
sudo podman run -d \
  --name=jellyfin \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -e JELLYFIN_PublishedServerUrl=192.168.0.5 `#optional` \
  -p 8096:8096 `# HTTP` \
  -p 8920:8920 `#optional HTTPS` \
  -p 7359:7359/udp `#optional Client Discover` \
  -p 1900:1900/udp `#optional DLNA Discover` \
  -v /path/to/library:/config \
  -v /path/to/tvseries:/data/tvshows \
  -v /path/to/movies:/data/movies \
  --device=/dev/video10:/dev/video10 \
  --device=/dev/video11:/dev/video11 \
  --device=/dev/video12:/dev/video12 \
  --restart always \
  lscr.io/linuxserver/jellyfin:latest
```

- 使用 `sudo podman ps` 验证是否启动
- 访问 `http://IP:8096/` 查看控制台
