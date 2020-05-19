#!/bin/bash

# call setup_opensg.sh first!

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

libDir="/c/usr/lib"
incDir="/c/usr/include"

if [ ! -e $libDir ]; then 
	mkdir -p $libDir 
fi
if [ ! -e $incDir ]; then 
	mkdir -p $incDir 
fi

function downloadRepository {
	cd $DIR
	if [ ! -e $1 ]; then
		echo "download $1 source"
		git clone ${@:2} $1
	else
		echo "$1 source allready present"
	fi
}

downloadRepository libxml2 https://github.com/GNOME/libxml2.git
downloadRepository freetype2 https://git.savannah.gnu.org/git/freetype/freetype2.git
downloadRepository cpython --branch 2.7 https://github.com/Victor-Haefner/cpython.git
downloadRepository tiff https://gitlab.com/libtiff/libtiff.git
downloadRepository gdal https://github.com/Victor-Haefner/gdal.git
downloadRepository gdal/proj https://github.com/Victor-Haefner/PROJ.git
downloadRepository polyvr https://github.com/Victor-Haefner/polyvr.git

# --------------------- freetype2

if [ ! -e $DIR/freetype2/build ]; then
	cd $DIR/freetype2
	mkdir build && cd build
	cmake -G "Visual Studio 15 2017 Win64" ..
	cmake --build . --config Release
	cp -r $DIR/freetype2/include/* $incDir/
	cp -r $DIR/freetype2/build/include/freetype/* $incDir/freetype/
	cp build/Release/freetype.lib $libDir/
fi

# --------------------- libxml2

if [ ! -e $libDir/libxml2.lib ]; then
	cd $DIR/libxml2/win32
	cmd //C $DIR/compile_libxml2.bat
fi

# --------------------- python c api

if [ ! -e $libDir/python27.lib ]; then
	cd $DIR/cpython/PCbuild
	cmd //C $DIR/compile_cpython.bat
	cp $DIR/cpython/PCbuild/amd64/* $libDir/
	cp $DIR/cpython/Include/*.h $incDir/Python/
	cp $DIR/cpython/PC/pyconfig.h $incDir/Python/
fi

exit 0

# --------------------- lib tiff # TODO: move this to setupOSG

if [ ! -e tiff/Build ]; then
	cd tiff
	mkdir Build && cd Build
	zlib="-DZLIB_INCLUDE_DIR=~/.emscripten_ports/zlib/zlib-version_1 -DZLIB_LIBRARY_RELEASE=~/.emscripten_cache/wasm-obj/libz.a"
	imgJpg="-DJPEG_INCLUDE_DIR=~/.emscripten_ports/libjpeg/jpeg-9c -DJPEG_LIBRARY_RELEASE=~/.emscripten_cache/wasm-obj/libjpeg.a"
	cmake ../ $zlib $imgJpg # TODO: jpeg not yet taken into account..
	make -j8
	cp port/*.a $libDir
	cp libtiff/*.a $libDir
	cp -r ../libtiff $incDir/libtiff
	cp libtiff/*.h $incDir/libtiff/
fi


# --------------------- lib gdal

cd $DIR
if [ ! -e gdal/proj/build ]; then
	cd gdal/proj
	mkdir build && cd build
	cmake ../ -DWITHOUT_SQLITE=1 -DENABLE_CURL=0 -DBUILD_TESTING=0 -DBUILD_PROJSYNC=0 -DTIFF_INCLUDE_DIR="../$incDir/libtiff" -DTIFF_LIBRARY="../$libDirlibtiffxx.a"
	make -j8
	cp lib/libproj.a $libDir
	cp -r ../src $incDir/libproj
	cp src/*.h $incDir/libproj/
	cp -r ../include/proj $incDir/libproj/
fi

cd $DIR	
if [ ! -e gdal/gdal/build ]; then
	cd gdal/gdal # configure needs to run in this folder!
	./configure \
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
	make -j8
        make force-lib
	cp libgdal.a $libDir
	mkdir $incDir/gdal
	find . -name "*.h" -exec cp {} $incDir/gdal/ \;
	cp port/cpl_config.h $incDir/gdal/ # needs to override wrong config
	#cp port/*.h $incDir/gdal/ #test
fi

exit 0


# --------------------- polyvr

if [ ! -e $DIR/polyvr/build ]; then
	cd $DIR/polyvr
	mkdir build && cd build
	cmake -G "Visual Studio 15 2017 Win64" ..
	cmake --build . --config Release
fi
fi


