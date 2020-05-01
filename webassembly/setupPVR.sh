#!/bin/bash

# call setupOSG.sh first!

# get script directory
SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]
do 
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
cd $DIR

source emsdk/emsdk_env.sh --build=Release

# --------------------- libxml2

cd $DIR
if [ ! -e libxml2 ]; then
	echo "get libxml2 source"
	git clone https://github.com/GNOME/libxml2.git
fi

if [ ! -e libxml2/build ]; then
	cd libxml2
	./autogen.sh
	mkdir build && cd build
	emconfigure ../configure --without-python
	emmake make
	cp .libs/*.a ../../lib
	cp -r ../include ../../include/libxml2
	cp include/libxml/xmlversion.h ../../include/libxml2/libxml/
fi


# --------------------- python c api

cd $DIR
if [ ! -e cpython ]; then
	echo "get cpython source"
	git clone --branch 2.7 https://github.com/Victor-Haefner/cpython.git
fi

# TODO: python currently compiles with -g flag (debug)
if [ ! -e cpython/build ]; then
	cd cpython
	mkdir build && cd build
	emconfigure ../configure
	emmake make
	cp libpython2.7.a ../../lib
	cp -r ../Include ../../include/Python
	cp pyconfig.h ../../include/Python/
fi


# --------------------- lib tiff # TODO: move this to setupOSG

cd $DIR
if [ ! -e tiff ]; then
	echo "get tiff source"
	git clone https://gitlab.com/libtiff/libtiff.git tiff
fi

if [ ! -e tiff/Build ]; then
	cd tiff
	mkdir Build && cd Build
	zlib="-DZLIB_INCLUDE_DIR=~/.emscripten_ports/zlib/zlib-version_1 -DZLIB_LIBRARY_RELEASE=~/.emscripten_cache/wasm-obj/libz.a"
	imgJpg="-DJPEG_INCLUDE_DIR=~/.emscripten_ports/libjpeg/jpeg-9c -DJPEG_LIBRARY_RELEASE=~/.emscripten_cache/wasm-obj/libjpeg.a"
	emcmake cmake ../ $zlib $imgJpg # TODO: jpeg not yet taken into account..
	emmake make -j8
	cp port/*.a ../../lib/
	cp libtiff/*.a ../../lib/
	cp -r ../libtiff ../../include/libtiff
	cp libtiff/*.h ../../include/libtiff/
fi


# --------------------- lib gdal

cd $DIR
if [ ! -e gdal ]; then
	echo "get gdal source"
	git clone https://github.com/Victor-Haefner/gdal.git gdal
fi

if [ ! -e gdal/proj ]; then
	echo "get gdal proj source"
	git clone https://github.com/Victor-Haefner/PROJ.git gdal/proj
fi


cd $DIR
if [ ! -e gdal/proj/build ]; then
	cd gdal/proj
	mkdir build && cd build
	emcmake cmake ../ -DWITHOUT_SQLITE=1 -DENABLE_CURL=0 -DBUILD_TESTING=0 -DBUILD_PROJSYNC=0 -DTIFF_INCLUDE_DIR="../../../include/libtiff" -DTIFF_LIBRARY="../../../lib/libtiffxx.a"
	emmake make -j8
	cp lib/libproj.a ../../../lib/
	cp -r ../src ../../../include/libproj
	cp src/*.h ../../../include/libproj/
	cp -r ../include/proj ../../../include/libproj/
fi

cd $DIR	
if [ ! -e gdal/gdal/build ]; then
	cd gdal/gdal # configure needs to run in this folder!
	emconfigure ./configure \
  --with-python=no \
  --with-crypto=no \
  --with-opencl=no \
  --with-geos=no \
  --with-curl=no \
  --with-xml2=no \
  --with-libkml=no \
  --with-mysql=no \
  --with-netcdf=no \
  --with-pcraster=internal \
  --with-pg=no \
  --with-proj_include="-I$DIR/include/libproj" \
  --with-proj_lib="-L$DIR/lib -lproj" \
  --with-cryptopp=no \
  --with-java=no \
  --with-libjson-c=internal \
  --with-libz=no \
  --with-libz_include="-I$HOME/.emscripten_ports/zlib/zlib-version_1" \
  --with-libz_lib="-L$HOME/.emscripten_cache/wasm-obj" \
  --with-hdf5=no \
  --with-expat=no \
  --with-oci=no \
  --with-oci-lib=no \
  --with-oci-include=no \
  --with-geotiff=internal \
  --with-libtiff="$DIR/include/libtiff" \
  --with-grass=no \
  --with-spatialite=no \
  --with-freexl=no
	emmake make -j8
        emmake make force-lib
	cp libgdal.a ../../lib/
	mkdir ../../include/gdal
	find . -name "*.h" -exec cp {} ../../include/gdal/ \;
	cp port/cpl_config.h ../../include/gdal/ # needs to override wrong config
	#cp port/*.h ../../include/gdal/ #test
fi


# --------------------- polyvr

cd $DIR
if [ ! -e polyvr ]; then
	echo "get polyvr source"
	git clone https://github.com/Victor-Haefner/polyvr.git
	cd polyvr
	mkdir build && cd build
	emcmake cmake ../
	emmake make -j8
	#emmake make -j8 && ../../pvr/hack_polyvr_js.sh && cp polyvr.* ../../pvr/
fi
