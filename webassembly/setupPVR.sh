#!/bin/bash

# call setupOSG.sh first!

sudo apt install sqlite3

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
	#git clone --branch 2.7 https://github.com/Victor-Haefner/cpython.git
	git clone --branch v3.14.1 https://github.com/python/cpython.git
fi

if [ ! -e cpython/build ]; then
	echo "--- setup cpython ---"
	cd cpython
	mkdir buildHost && cd buildHost
	../configure
	make -j4
	
	cd $DIR/cpython
	mkdir build && cd build

	# check in configure for what to disable
cat > config.site << 'EOF'
ac_cv_file__dev_ptmx=no
ac_cv_file__dev_ptc=no

ac_cv_func_fork=no
ac_cv_func_vfork=no
ac_cv_func_forkpty=no
ac_cv_func_pipe2=no
ac_cv_func_memfd_create=no
ac_cv_func_posix_fallocate=no
EOF
	
	CONFIG_SITE=$(pwd)/config.site emconfigure ../configure --with-ensurepip=no --host=wasm32-unknown-emscripten --build=$(../config.guess) --with-build-python=$(pwd)/../buildHost/python --disable-ipv6 --disable-shared --disable-test-modules --with-builtin-hashlib-hashes=no
	
	# TODO: try with --enable-optimizations

	mkdir web_example
	touch ../Python/pythonrun.c
	emmake make
	cp lib*.a ../../lib/
	cp Modules/expat/lib*.a ../../lib/
	cp Modules/_decimal/libmpdec/lib*.a ../../lib/
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
	#git clone https://github.com/Victor-Haefner/gdal.git gdal
	git clone https://github.com/OSGeo/gdal.git gdal
fi

if [ ! -e gdal/proj ]; then
	echo "get gdal proj source"
	#git clone https://github.com/Victor-Haefner/PROJ.git gdal/proj
	git clone https://github.com/OSGeo/PROJ.git gdal/proj
fi

if [ ! -e sqlite ]; then
	echo "get sqlite proj source"
	git clone https://github.com/sqlite/sqlite.git sqlite
fi

cd $DIR	
if [ ! -e sqlite/build ]; then
	echo "--- setup sqlite ---"
	cd sqlite
	mkdir build && cd build
	
	emconfigure ../configure --host=wasm32-unknown-emscripten --build=wasm32-unknown-emscripten --disable-readline --disable-tcl --disable-shared
	emmake make
	
	cp *.a ../../lib/
	mkdir ../../include/libsqlite
	cp *.h ../../include/libsqlite/
fi

cd $DIR
if [ ! -e gdal/proj/build ]; then
	echo "--- setup gdal proj ---"
	cd gdal/proj
	mkdir build && cd build
	emcmake cmake ../ -DENABLE_CURL=0 -DBUILD_TESTING=0 -DBUILD_PROJSYNC=0 -DTIFF_INCLUDE_DIR="$DIR/include/libtiff" -DTIFF_LIBRARY="$DIR/lib/libtiffxx.a" -DSQLite3_LIBRARY="$DIR/lib/libsqlite3.a" -DSQLite3_INCLUDE_DIR="$DIR/include/libsqlite" -DBUILD_SHARED_LIBS=OFF
	emmake make -j8 proj
	cp lib/libproj.a ../../../lib/
	cp -r ../src ../../../include/libproj
	cp src/*.h ../../../include/libproj/
	cp -r ../include/proj ../../../include/libproj/
	cp data/for_tests/proj.db ../../../include/libproj/
fi



cd $DIR	
if [ ! -e gdal/build ]; then
	echo "--- setup gdal ---"
	cd gdal # configure needs to run in this folder!
	mkdir build && cd build
  
	emcmake cmake .. \
	-DBUILD_SHARED_LIBS=OFF \
	-DGDAL_BUILD_OPTIONAL_DRIVERS=OFF \
	-DOGR_BUILD_OPTIONAL_DRIVERS=OFF \
	-DACCEPT_MISSING_SQLITE3_MUTEX_ALLOC=ON \
	\
	-DGDAL_USE_PROTOBUF=OFF \
	-DGDAL_USE_CURL=OFF \
	-DGDAL_USE_XML2=OFF \
	-DGDAL_USE_LIBKML=OFF \
	-DGDAL_USE_MYSQL=OFF \
	-DGDAL_USE_NETCDF=OFF \
	-DGDAL_USE_GEOS=OFF \
	-DGDAL_USE_HDF5=OFF \
	-DGDAL_USE_EXPAT=OFF \
	-DGDAL_USE_OCI=OFF \
	-DGDAL_USE_PCRASTER=OFF \
	-DGDAL_USE_LIBJSONC_INTERNAL=ON \
	\
	-DGDAL_USE_ZLIB=ON \
	-DZLIB_INCLUDE_DIR="$DIR/emsdk/upstream/emscripten/cache/ports/zlib" \
	-DZLIB_LIBRARY="$DIR/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten/libz.a" \
	\
	-DGDAL_USE_TIFF=ON \
	-DTIFF_INCLUDE_DIR=$DIR/include/libtiff \
	-DTIFF_LIBRARY=$DIR/lib/libtiff.a \
	-DGDAL_USE_GEOTIFF_INTERNAL=ON \
	\
	-DPROJ_INCLUDE_DIR=$DIR/include/libproj \
	-DPROJ_LIBRARY=$DIR/lib/libproj.a \
	\
	-DBUILD_PYTHON_BINDINGS=OFF \
	-DBUILD_JAVA_BINDINGS=OFF \
	-DBUILD_CSHARP_BINDINGS=OFF \
	-DBUILD_CPP_BINDINGS=OFF \
	-DBUILD_SWIG_PYTHON=OFF \
	-DBUILD_SWIG_JAVA=OFF \
	-DBUILD_SWIG_CSHARP=OFF

	emmake make -j8 GDAL
	cp libgdal.a ../../lib/
	mkdir ../../include/gdal
	find . -name "*.h" -exec cp {} ../../include/gdal/ \;
	find ../gcore -name "*.h" -exec cp {} ../../include/gdal/ \;
	find ../port -name "*.h" -exec cp {} ../../include/gdal/ \;
	find ../ogr -name "*.h" -exec cp {} ../../include/gdal/ \;
	cp port/cpl_config.h ../../include/gdal/ # needs to override wrong config
	#cp port/*.h ../../include/gdal/ #test
fi

cd $DIR	
if [ ! -e include/eigen ]; then
	echo "get eigen source"
	git clone https://github.com/PX4/eigen.git
	mv eigen include/
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









