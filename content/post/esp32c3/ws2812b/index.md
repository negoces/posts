---
title: "ESP-IDF 点亮 WS2812B"
description: "嵌入式第一步，点亮LED"
date: 2023-03-27T20:52:03+08:00
slug: 1eb238e0
#image: "cover.png"
tags: [ESP32C3, WS2812B, ESP-IDF]
categories: ESP32C3
---

## 创建工程

- 文件结构:

```bash
WS2812B
├── CMakeLists.txt
└── main
    ├── CMakeLists.txt
    └── main.c
```

- `CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.16)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(WS2812B)
```

- `main/CMakeLists.txt`

```cmake
idf_component_register(SRCS "main.c" INCLUDE_DIRS "")
```

- `main/main.c`

```c
#include <stdio.h>
#include "sdkconfig.h"

void app_main(void)
{
    printf("Hello world!\n");
    fflush(stdout);
}
```

## 工程配置与烧写测试

```bash
idf.py set-target esp32c3
idf.py menuconfig
idf.py build
idf.py flash monitor
```

> Matter 安装所需包
>
> - `libgirepository` - `libgirepository-1.0.so.1`