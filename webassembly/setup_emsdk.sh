#!/bin/bash
# for webassembly development

if [ ! -e emsdk ]; then
	git clone https://github.com/emscripten-core/emsdk.git
fi

cd emsdk
./emsdk install latest
./emsdk activate latest

source ./emsdk_env.sh --build=Release

cd ..
emcc setupPorts.cpp -std=c++11 -s WASM=1 -s USE_PTHREADS=1 -s USE_SDL=2 -O3 -o sdlTest.js -s USE_BOOST_HEADERS=1 -s USE_ZLIB=1 -s USE_LIBJPEG=1 -s USE_LIBPNG -s USE_FREETYPE

# TODO:
# check available ports in upstream/emscripten/src/settings.js
#  USE_BULLET=1
#  USE_HARFBUZZ=1   # this was used for a dependency, dont remember which..
# multi threading with PTHREAD_POOL_SIZE ?
