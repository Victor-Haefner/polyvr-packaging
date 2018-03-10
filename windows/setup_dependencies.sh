#!/bin/bash

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

export VSCMD_START_DIR=$DIR
/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2017/Community/VC/Auxiliary/Build/vcvarsall.bat x86_amd64
	
# get boost -> TODO
#  download boost binaries, see wiki on github!
#  https://sourceforge.net/projects/boost/files/boost-binaries/1.65.1/boost_1_65_1-msvc-14.1-64.exe/download

export BOOST_INCLUDEDIR="/c/boost"
export BOOST_ROOT="/c/boost"
export Boost_FILESYSTEM_LIBRARY_Debug="/c/boost/lib64-msvc-14.1/boost_filesystem-vc141-mt-1_65_1.dll"
export Boost_FILESYSTEM_LIBRARY_RELEASE="/c/boost/lib64-msvc-14.1/boost_filesystem-vc141-mt-1_65_1.dll"
export Boost_SYSTEM_LIBRARY_Debug="/c/boost/lib64-msvc-14.1/boost_system-vc141-mt-1_65_1.dll"
export Boost_SYSTEM_LIBRARY_RELEASE="/c/boost/lib64-msvc-14.1/boost_system-vc141-mt-1_65_1.dll"
export ZLIB_INCLUDE_DIR="/c/zlib"
export ZLIB_LIBRARY_DEBUG="/c/zlib/zlib.lib"
export ZLIB_LIBRARY_RELEASE="/c/zlib/zlib.lib"
export GLUT_INCLUDE_DIR="/c/freeglut"
export GLUT_glut_LIBRARY_DEBUG="/c/freeglut/freeglutd.dll"
export GLUT_glut_LIBRARY_RELEASE="/c/freeglut/freeglutd.dll"

# get zlib
cd $DIR
if [ ! -e zlib/.git ]; then
	git clone https://github.com/madler/zlib.git zlib
	mkdir zlib/build
	cd zlib/build
	cmake -G "Visual Studio 15 2017 Win64" ..
	cmake --build . --config Release
	mkdir /c/zlib
	cp zconf.h /c/zlib/
	cp ../*.h /c/zlib/
	cp Release/* /c/zlib/
fi

# get freeglut
cd $DIR
if [ ! -e FreeGLUT/.git ]; then
	git clone https://github.com/dcnieho/FreeGLUT.git FreeGLUT
	mkdir FreeGLUT/build
	cd FreeGLUT/build
	cmake -G "Visual Studio 15 2017 Win64" ../freeglut/freeglut
	cmake --build . --config Release
	mkdir /c/freeglut
	cp bin/Release/* /c/freeglut/
	cp lib/Release/* /c/freeglut/
	cp *.h /c/freeglut/
	cp -r ../freeglut/freeglut/include/* /c/freeglut/
fi

# get OpenSG source from git
cd $DIR
if [ ! -e OpenSG/.git ]; then
  git clone https://github.com/Victor-Haefner/OpenSGDevMaster.git OpenSG
fi

# compile OpenSG
cd $DIR
if [ ! -e OpenSG/build ]; then
  mkdir OpenSG/build
  cd OpenSG/build
  cmake -G "Visual Studio 15 2017 Win64" -DOSGBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DGLUT_INCLUDE_DIR="/c/freeglut" -DGLUT_glut_LIBRARY_RELEASE="/c/freeglut/freeglut.lib" -DZLIB_INCLUDE_DIR="/c/zlib" -DZLIB_LIBRARY_RELEASE="/c/zlib/zlib.lib" -DBoost_FILESYSTEM_LIBRARY_RELEASE="/c/boost/lib64-msvc-14.1/boost_filesystem-vc141-mt-1_65_1.lib" -DBoost_SYSTEM_LIBRARY_RELEASE="/c/boost/lib64-msvc-14.1/boost_system-vc141-mt-1_65_1.lib" ..
  cmake --build . --config Release
  d_inc=/c/opensg/include/OpenSG/
  mkdir -p $d_inc
  
  cd $DIR
  find OpenSG/Source -name "*.h" -exec cp {} $d_inc \;
  find OpenSG/Source -name "*.inl" -exec cp {} $d_inc \;
  find OpenSG/build/Source -name "*.h" -exec cp {} $d_inc \;
  cp OpenSG/Source/WindowSystem/X/OSGNativeWindow.h $d_inc
  cp -r OpenSG/build/bin/Release/* /c/opensg/
  
fi




