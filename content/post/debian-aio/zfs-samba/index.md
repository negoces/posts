---
title: "Debian 网关 [Episode 06]: 创建 ZFS 卷并启用 Samba"
description: "实现基础 NAS 功能"
date: 2023-04-19T11:35:40+08:00
slug: b6b316de
#image: "cover.png"
tags: [Debian, NAS, OpenZFS, Samba]
categories: Debian Router
---

## ZFS 存储结构

```text
+--------------+--------------+
|      fs      |      fs      |
+--------------+--------------+
|             pool            |
+---------+---------+---------+
|   dev   |   dev   |   dev   |
+---------+---------+---------+
```

## 安装 OpenZFS

```bash
sudo apt update
sudo apt install linux-headers-generic zfsutils-linux
```

## 创建 zpool

### 获取磁盘路径

```bash
# 指令:
ls -l /dev/disk/by-id/

# 示例输出
lrwxrwxrwx root root scsi-3600224803625601411d7b9ac385fe7e5 -> ../../sda
lrwxrwxrwx root root scsi-3600224808706cf11a87183b8497a2b6e -> ../../sdc
lrwxrwxrwx root root scsi-360022480f059432a0118aadee2d973ff -> ../../sdb
lrwxrwxrwx root root wwn-0x600224803625601411d7b9ac385fe7e5 -> ../../sda
lrwxrwxrwx root root wwn-0x600224808706cf11a87183b8497a2b6e -> ../../sdc
lrwxrwxrwx root root wwn-0x60022480f059432a0118aadee2d973ff -> ../../sdb

# 记下其中对应磁盘的 scsi-xxxxxxxx 或 ata-xxxxxxxx 或 nvme-xxxxxxxx
```

### 创建 zpool

**`${POOL_NAME} 换成存储池名称`**

- 单磁盘
    ```bash
    sudo zpool create ${POOL_NAME} scsi-xxxxxxxx
    ```
- stripe ( RAID0 )
    ```bash
    sudo zpool create ${POOL_NAME} scsi-xxxxxxxx scsi-xxxxxxxx
    ```
- mirror ( RAID1 )
    ```bash
    sudo zpool create ${POOL_NAME} mirror scsi-xxxxxxxx scsi-xxxxxxxx
    ```
- raidz1 ( RAID5 )
    ```bash
    sudo zpool create ${POOL_NAME} raidz scsi-xxxxxxxx scsi-xxxxxxxx
    ```
- 更多其他组合请参考: <https://wiki.debian.org/ZFS#Creating_the_Pool>

### 查看 zpool

```bash
# 指令:
sudo zpool list

# 示例输出
NAME   SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
data  1.81T   372K  1.81T        -         -     0%     0%  1.00x    ONLINE  -
```

## 创建 zfs

### 常规创建

```bash
sudo zfs create data/share
```

### 自定义挂载点

```bash
sudo mkdir -p /share
sudo zfs create -o mountpoint=/share data/share
```

### 查看 zfs

```bash
# 指令:
sudo zfs list

# 示例输出
NAME         USED  AVAIL     REFER  MOUNTPOINT
data         564K  1.76T       96K  /data
data/share    96K  1.76T       96K  /data/share
```

## 数据去重 | Deduplication

{{<hint warning>}}
**Tips:**

- **块级去重** 与 **压缩** 和 **加密** 冲突
- **去重对性能损耗极为严重，尤其是 HDD，建议设置完后参考下文的【写入性能测试】至少写入 8GB 的数据对磁盘速度进行测试**
{{</hint>}}

- Debian Bookworm 目前支持的去重方式
    - `on`
    - `off`
    - `verify`
    - `sha256[,verify]`
    - `sha512[,verify]`
    - `skein[,verify]`
    - `edonr,verify`
    - 其中：
        - `sha256`、`sha512`、`skein`、`edonr` 为散列方式；
        - `[]` 内为可选项，使用时要将括号去除；
        - 带 `verify` 的为块级去重，不带则为文件去重；
        - `off` 为关闭，`on` 默认为 `sha256`；

- 如何查看本机支持的去重方式:
    ```bash
    # 原理是给 dedup 一个无效属性，它就会告诉你支持哪些
    sudo zfs set dedup=help ${POOL_NAME}
    ```
- 设置去重

```bash
sudo zfs set dedup=on ${FS_NAME}
```

## 数据压缩 | Compression

- 查看本机支持的压缩方式，与上文【去重】相同，将 `dedup` 替换为 `compression` 即可
- 启用压缩
    ```bash
    sudo zfs set compression=on ${FS_NAME}
    ```

## 写入性能测试


```bash
cd /data/share
sudo dd if=/dev/urandom of=16G.test bs=64K count=262144 status=progress
sudo dd if=/dev/urandom of=8G.test bs=4M count=2048 status=progress
```

## Samba 服务

### 安装 Samba

```bash
sudo apt install samba
```

### 配置 Samba

- 备份原有配置
    ```bash
    sudo systemctl stop smbd
    sudo mv /etc/samba/smb.conf{,.bak}
    ```
- 写入新配置
    ```ini
    # /etc/samba/smb.conf
    [global]
    server string = Samba(%v): %h
    workgroup = WORKGROUP
    # If has Apple devices set SMB2
    server min protocol = SMB3
    server max protocol = SMB3
    # Set off if CPU unsupport AES offloading
    server smb encrypt = desired
    server multi channel support = yes

    [share]
    path = /data/share
    create mask = 0755
    browseable = yes
    writeable = yes
    public= no
    ```
**Tips:** 加密测速指令:

```bash
# 单线程
openssl speed -aead -evp aes-128-gcm
# 多线程
openssl speed -aead -evp aes-128-gcm -multi $(nproc)
```

### 启动 Samba

```bash
sudo systemctl restart smbd
```

### 设置用户密码

**Tips:** 用户必须是已存在的 Unix 用户

```bash
# New User
sudo smbpasswd -a ${USER}
# Reset Password
sudo smbpasswd ${USER}
```
