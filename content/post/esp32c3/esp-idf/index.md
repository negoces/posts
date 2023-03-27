---
title: "安装 ESP-IDF"
description: "在 Linux 上安装 ESP-IDF 开发环境"
date: 2023-03-27T15:26:02+08:00
slug: 25e0fcde
#image: "cover.png"
tags: [ESP32C3, Linux, Espressif]
categories: ESP32C3
---

## 安装依赖

- Debian 系

```bash
sudo apt-get install git wget flex bison gperf python3 python3-venv python3-setuptools cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0
```

- Arch Linux

```bash
sudo pacman -S --needed gcc git make flex bison gperf python cmake ninja ccache dfu-util libusb
```

~~CentOS 就是孤儿~~

## Clone ESP-IDF

以 `release/v5.0` 版本为例

```bash
git clone -b release/v5.0 --depth 1 --recursive https://github.com/espressif/esp-idf.git ${HOME}/.local/opt/esp-idf-v5.0
```

{{<hint info>}}
**如果中途 clone 子模块失败:**

1. 切换到 ESP-IDF 目录: `cd ~/.local/opt/esp-idf-v5.0`
2. 更新子模块: `git submodule update --init --recursive`

{{</hint>}}

## 设置 ESP-IDF

{{<hint info>}}
使用 `export IDF_GITHUB_ASSETS="dl.espressif.com/github_assets"` 可以提升部分文件在大陆地区下载的速度
{{</hint>}}

1. 切换到 ESP-IDF 目录: `cd ~/.local/opt/esp-idf-v5.0`
1. 设置工具链安装位置
    - 创建文件夹: `mkdir -p ~/.local/opt/esp-tools`
    - 设置临时环境变量 `export IDF_TOOLS_PATH=${HOME}/.local/opt/esp-tools`
    - 若不设置，则会安装到 `~/.espressif`
1. 设置对于设备的工具链
    - 如果是 ESP32-C3 等某一个设备: `./install.sh esp32c3`
    - 如果是多个设备: `./install.sh esp32c3,esp32`
    - 如果是所有被 ESP-IDF 支持的设备: `./install.sh all`
1. 设置环境变量
    - 为 esp-idf-v5.0.1 文件夹创建软链，方便切换版本
        - 进入文件夹: `cd ${HOME}/.local/opt`
        - 创建链接: `ln -s -T esp-idf-v5.0 esp-idf`
    - 设置环境变量，**前置条件: [Linux 设置环境变量](/post/0e62ab6b/)**
        - 创建编辑 `${HOME}/.local/profile.d/esp.sh` 并添加：
        - `export IDF_CCACHE_ENABLE=1`
        - `export IDF_PATH=${HOME}/.local/opt/esp-idf`
        - `export IDF_TOOLS_PATH=${HOME}/.local/opt/esp-tools`
1. 激活环境: `. ${IDF_PATH}/export.sh`

## 编译测试

### 复制示例

```bash
mkdir ~/ESPProjets
cd ~/ESPProjets
cp -r $IDF_PATH/examples/get-started/hello_world .
cd hello_world
```

### 配置工程

```bash
idf.py set-target esp32c3
idf.py menuconfig
```

### 编译&烧录&监视

```bash
idf.py build
idf.py [ -p $PORT ] flash
idf.py [ -p $PORT ] monitor
# or
idf.py flash monitor
```

{{<hint info>}}
**WSL2下使用串口请参考:**

- Windows 安装: <https://github.com/dorssel/usbipd-win>
- Linux 安装: `usbip`
- 使用方法:
    - Windows:
        - `usbipd list`
        - `usbipd bind --force --busid=<busid>` (管理员)
    - Linux:
        - `usbip list --remote=<host>`
        - `sudo usbip list --remote=<host> --busid=<busid>`

**在 Arch Linux 上没有权限访问串口:**

- `sudo usermod -aG uucp ${USER}`
- 重新登录
{{</hint>}}
