#!/bin/bash

# call
#  emcc sdlTest.cpp -std=c++11 -s WASM=1 -s USE_PTHREADS=1 -s USE_SDL=2 -O3 -o sdlTest.js -s USE_BOOST_HEADERS=1 -s USE_ZLIB=1 -s USE_LIBJPEG=1 -s USE_LIBPNG
# to easily install wasm ports

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

echo "--- setup Boost --- $DIR"

source emsdk/emsdk_env.sh --build=Release
DIR=$DIRtmp

# --------------------- boost filesystem and boost system

cd $DIR
if [ ! -e lib ]; then
	mkdir lib
fi

if [ ! -e boost ]; then
	echo "get boost source"
	git clone https://github.com/boostorg/boost
	cd boost
	git submodule update --init
fi

cd $DIR
if [ ! -e lib/libboost_system.a ]; then
	echo "setup boost libs"
	cd $DIR/boost
	./bootstrap.sh --prefix=../
	echo " ---- bootstrap done ----"
	#./b2 toolset=emscripten link=static variant=release threading=single runtime-link=static system thread program_options serialization filesystem regex
	./b2 toolset=emscripten link=static variant=release threading=single runtime-link=static system program_options serialization filesystem
	echo " ---- b2 done ----"
	systemBC="$( find . -name libboost_system.bc )" 
	filesystemBC="$( find . -name libboost_filesystem.bc )" 
	programoptionsBC="$( find . -name libboost_program_options.bc )"
	serializationBC="$( find . -name libboost_serialization.bc )"
	echo " -- systemBC: $systemBC"
	echo " -- filesystemBC: $filesystemBC"
	echo " -- programoptionsBC: $programoptionsBC"
	echo " -- serializationBC: $serializationBC"
	emar q ../lib/libboost_system.a $systemBC
	emar q ../lib/libboost_filesystem.a $filesystemBC
	emar q ../lib/libboost_program_options.a $programoptionsBC
	emar q ../lib/libboost_serialization.a $serializationBC
fi


# ------------------------------- OpenSG
echo "setup opensg"

cd $DIR
if [ ! -e OpenSG/.git ]; then
	git clone https://github.com/Victor-Haefner/OpenSGDevMaster.git OpenSG
fi

if [ ! -e OpenSG/build ]; then
	cd OpenSG

	target=Debug #Release
	flags="-Wno-dev -H. -Bbuild -DWASM=1 -DOSGBUILD_TESTS=OFF -DOSGBUILD_OSGContribCgFX=0 -DCMAKE_BUILD_TYPE=Debug -DOSGBUILD_OSGContribCSM=0 -DOSGBUILD_OSGContribCSMSimplePlugin=0"
	#flags2="-DOSG_OGL_COREONLY=ON -DOSG_USE_OGLES_PROTOS=ON -DOSG_OGL_ES2=ON -DOSG_OGL_NO_DOUBLE=ON"
	flags2="-DOSG_OGL_COREONLY=ON -DOSG_OGL_ES2=ON -DOSG_OGL_NO_DOUBLE=ON"
	#toolchainPath=	
	toolchain="-DCMAKE_TOOLCHAIN_FILE=$DIR/emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake -DCMAKE_MODULE_PATH=$DIR/emsdk/upstream/emscripten/cmake/Modules"
	emsdkLibDir="$DIR/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten"	
	zlib="-DZLIB_INCLUDE_DIR=$DIR/emsdk/upstream/emscripten/cache/ports-builds/zlib -DZLIB_LIBRARY_RELEASE=$emsdkLibDir/libz.a"
	bLib="$emsdkLibDir/libboost_headers.a"
	bRoot="$DIR/emsdk/upstream/emscripten/cache/ports-builds/boost_headers"	
	boost="-DBOOST_ROOT=$bRoot -DBoost_FILESYSTEM_LIBRARY_RELEASE=$bLib -DBoost_SYSTEM_LIBRARY_RELEASE=$bLib -DBoost_FILESYSTEM_LIBRARY_DEBUG=$bLib -DBoost_SYSTEM_LIBRARY_DEBUG=$bLib"
	glut="-DGLUT_INCLUDE_DIR=$DIR/emsdk/upstream/emscripten/system/include -DGLUT_glut_LIBRARY=1 -DGLUT_Xi_LIBRARY=1 -DGLUT_Xmu_LIBRARY=1"
	imgPng="-DPNG_INCLUDE_DIR=$DIR/emsdk/upstream/emscripten/cache/ports-builds/libpng -DPNG_LIBRARY_RELEASE=$emsdkLibDir/libpng.a"
	imgJpg="-DJPEG_INCLUDE_DIR=$DIR/emsdk/upstream/emscripten/cache/ports-builds/libjpeg -DJPEG_LIBRARY_RELEASE=$emsdkLibDir/libjpeg.a"
	cmd="emcmake cmake $flags $flags2 $toolchain $zlib $boost $glut $imgPng $imgJpg"
	echo $cmd
	echo
	$cmd

	cd build
	emmake make -j8
fi

d_inc=$DIR/include/OpenSG/
d_lib=$DIR/lib
mkdir -p $d_inc
mkdir -p $d_lib
rm $DIR/lib/libOSG*
rm $DIR/include/OpenSG/*

cd $DIR
find OpenSG/Source -name "*.h" -exec cp {} $d_inc \;
find OpenSG/Source -name "*.inl" -exec cp {} $d_inc \;
find OpenSG/build/Source -name "*.h" -exec cp {} $d_inc \;
cp OpenSG/Source/WindowSystem/WASM/OSGNativeWindow.h $d_inc
cp -r OpenSG/build/bin/* $d_lib/




