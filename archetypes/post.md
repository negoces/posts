---
title: "{{ replace .Name "-" " " | title }}"
description: "description"
date: {{ .Date }}
slug: {{ substr ( ( printf "%s%s" .Date .Name ) | base64Encode | sha256 ) -8 }}
#image: "cover.png"
tags: []
categories: undefined
---

Summary

<!--more-->