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
DIRtmp=$DIR

source emsdk/emsdk_env.sh --build=Release
DIR=$DIRtmp

# --------------------- libxml2

cd $DIR
if [ ! -e libxml2 ]; then
	echo "get libxml2 source"
	git clone https://github.com/GNOME/libxml2.git
fi

if [ ! -e libxml2/build ]; then
	echo "--- setup libxml2 ---"
	cd libxml2
	./autogen.sh
	rm config.status
	mkdir build && cd build
	emconfigure ../configure --without-python --disable-shared
	echo "--- libxml2 emconfigure done ---"
	emmake make
	echo "--- libxml2 emmake done ---"
	cp .libs/*.a ../../lib
	cp -r ../include ../../include/libxml2
	cp include/libxml/xmlversion.h ../../include/libxml2/libxml/
fi

# --------------------- python c api

cd $DIR
if [ ! -e cpython ]; then
	echo "get cpython source"
	git clone --branch 2.7 https://github.com/Victor-Haefner/cpython.git
	sed -i 's/#define HAVE_POPEN      1/#undef HAVE_POPEN/g' cpython/Modules/posixmodule.c
fi

# TODO: python currently compiles with -g flag (debug)    ..test if this is still the case
if [ ! -e cpython/build ]; then
	echo "--- setup cpython ---"
	cd cpython
	mkdir build && cd build
	emconfigure ../configure --with-ensurepip=no --enable-optimizations --with-lto --with-threads=no

	sed -i 's/#define HAVE_PLOCK 1/#undef HAVE_PLOCK/g' pyconfig.h
	sed -i 's/#define HAVE_INITGROUPS 1/#undef HAVE_INITGROUPS/g' pyconfig.h

	touch ../Python/pythonrun.c
	emmake make
	cp libpython2.7.a ../../lib
	cp -r ../Include ../../include/Python
	cp pyconfig.h ../../include/Python/
fi

# --------------------- lib tiff # TODO: move this to setupOSG

cd $DIR
if [ ! -e tiff ]; then
	echo "get tiff source"
	#git clone https://gitlab.com/libtiff/libtiff.git tiff --branch v4.1.0
	git clone https://gitlab.com/libtiff/libtiff.git tiff
fi

if [ ! -e tiff/Build ]; then
	echo "--- setup tiff ---"
	cd tiff
	git checkout a6d3c1d64b655f5f151a01fda2b7b0bf50cc61aa
	mkdir Build && cd Build
	emsdkLibDir="$DIR/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten"
	zlib="-DZLIB_INCLUDE_DIR=$DIR/emsdk/upstream/emscripten/cache/ports-builds/zlib -DZLIB_LIBRARY_RELEASE=$emsdkLibDir/libz.a"
	imgJpg="-DJPEG_INCLUDE_DIR=$DIR/emsdk/upstream/emscripten/cache/ports-builds/libjpeg -DJPEG_LIBRARY_RELEASE=$emsdkLibDir/libjpeg.a"
	emcmake cmake ../ $zlib $imgJpg # TODO: jpeg not yet taken into account..
	emmake make -j8
	cp port/*.a ../../lib/
	cp libtiff/*.a ../../lib/
	rm -rf ../../include/libtiff
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
	echo "--- setup gdal proj ---"
	cd gdal/proj
	mkdir build && cd build
	emcmake cmake ../ -DWITHOUT_SQLITE=1 -DENABLE_CURL=0 -DBUILD_TESTING=0 -DBUILD_PROJSYNC=0 -DTIFF_INCLUDE_DIR="../../../include/libtiff" -DTIFF_LIBRARY="../../../lib/libtiffxx.a"
	# comment #define HAVE_LIBDL 1	in proj_config.h
	emmake make -j8
	cp lib/libproj.a ../../../lib/
	cp -r ../src ../../../include/libproj
	cp src/*.h ../../../include/libproj/
	cp -r ../include/proj ../../../include/libproj/
fi

cd $DIR	
if [ ! -e gdal/gdal/build ]; then
	echo "--- setup gdal ---"
	cd gdal/gdal # configure needs to run in this folder!
	mkdir build # still, make the directory to make the if condition working
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
  --with-libz_include="-I$DIR/emsdk/upstream/emscripten/cache/ports-builds/zlib" \
  --with-libz_lib="-L$DIR/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten" \
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

# --------------------- cgal   TODO: needs gmp and mpfr

#cd $DIR
#if [ ! -e cgal ]; then
#	echo "--- clone cgal ---"
#	git clone https://github.com/Victor-Haefner/cgal.git --branch v4.14.3
#fi

#cd $DIR
#if [ ! -e include/CGAL ]; then
#	echo "--- copy cgal headers ---"
#	mkdir $DIR/include/CGAL
#	for f in cgal/*/include/CGAL/*; do
#		cp -rf "$f" $DIR/include/CGAL/
#	done
#fi

# --------------------- polyvr

cd $DIR
if [ ! -e polyvr ]; then
	echo "--- clone polyvr ---"
	git clone https://github.com/Victor-Haefner/polyvr.git
fi

if [ ! -e polyvr/build ]; then
	echo "--- compile polyvr ---"
	cd polyvr
	mkdir build && cd build
	emcmake cmake ../
	emmake make -j8 # VERBOSE=1
	#emmake make -j8 && ../../pvr/hack_polyvr_js.sh && cp polyvr.* ../../pvr/
fi

# HINTS when missing symbols:

#  search for a symbol:
#    grep SYMBOL lib/*

#  use llvm-nm to check the kind of symbol
#    emsdk/upstream/bin/llvm-nm lib/LIBRARY.a | grep SYMBOL









