#!/bin/bash

# Clean
rm -rf public/

HUGO_VER="0.111.2"

# Create `bin`
if [ ! -d "bin" ]; then
    mkdir -p bin
fi

if [ ! -f "bin/hugo" ]; then
    echo "Downloading hugo_extended_${HUGO_VER}_linux-amd64.tar.gz"
    if [ ! -d "tmp" ]; then
        mkdir -p tmp
    fi
    cd tmp
    curl -fLO "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VER}/hugo_extended_${HUGO_VER}_linux-amd64.tar.gz"
    tar xf "hugo_extended_${HUGO_VER}_linux-amd64.tar.gz" hugo
    chmod 755 hugo
    mv hugo ../bin
    cd ..
    rm -rf tmp
fi

bin/hugo --minify --templateMetrics --verbose