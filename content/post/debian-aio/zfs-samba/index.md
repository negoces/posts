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

- **块级去重**、**字节级去重** 与 **压缩** 和 **加密** 冲突
- **以下内容来自 Claude，无法保证准确性**
{{</hint>}}

### 关闭去重

```bash
sudo zfs set dedup=off ${POOL_NAME}
# or
sudo zfs set dedup=off ${FS_NAME}
```

### 文件级去重

```bash
sudo zfs set dedup=on ${POOL_NAME}
# or
sudo zfs set dedup=on ${FS_NAME}
```

### 块级去重

**Tips:** 默认块大小 128KB

```bash
sudo zfs set dedup=verify ${POOL_NAME}
# or
sudo zfs set dedup=verify ${FS_NAME}
```

### 字节级去重

```bash
sudo zfs set dedup=sha256,verify ${POOL_NAME}
# or
sudo zfs set dedup=sha256,verify ${FS_NAME}
```

## 数据压缩 | Compression

```bash
# zfs set compression=<gzip|lz4|zstd|off> <name>
sudo zfs set compression=lz4 ${POOL_NAME}
# or
sudo zfs set compression=lz4 ${FS_NAME}
```

## 写入性能测试

```bash
cd /data/share
sudo dd if=/dev/urandom of=4G.test bs=32K count=131072 status=progress
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
