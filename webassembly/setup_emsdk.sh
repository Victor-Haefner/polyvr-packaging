#!/bin/bash
# for webassembly development
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest

source ./emsdk_env.sh --build=Release
