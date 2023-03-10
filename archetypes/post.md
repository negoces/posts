---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
slug: {{ substr ( ( printf "%s%s" .Date .Name ) | base64Encode | sha256 ) -8 }}
#cover: "cover.png"
tags: []
categories: undefined
---

Summary

<!--more-->