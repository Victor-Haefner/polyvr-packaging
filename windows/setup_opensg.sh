#!/bin/bash

export ZLIB_INCLUDE_DIR="/c/zlib"
export ZLIB_LIBRARY_DEBUG="/c/zlib/zlib.lib"
export ZLIB_LIBRARY_RELEASE="/c/zlib/zlib.lib"
export GLUT_INCLUDE_DIR="/c/freeglut"
export GLUT_glut_LIBRARY_DEBUG="/c/freeglut/freeglut.dll"
export GLUT_glut_LIBRARY_RELEASE="/c/freeglut/freeglut.dll"

# get dependencies
cd $DIR
if [ ! -e zlib/.git ]; then
	git clone https://github.com/madler/zlib.git zlib
fi

if [ ! -e FreeGLUT/.git ]; then
	git clone https://github.com/dcnieho/FreeGLUT.git FreeGLUT
fi

if [ ! -e OpenSG/.git ]; then
	git clone https://github.com/Victor-Haefner/OpenSGDevMaster.git OpenSG
fi

# compile dependencies
cd $DIR
if [ ! -e zlib/build ]; then
	echo "compile zlib"
	mkdir zlib/build
	cd zlib/build
	cmake -G "$VSgenerator" ..
	cmake --build . --config Release
	mkdir /c/zlib
	cp zconf.h /c/zlib/
	cp ../*.h /c/zlib/
	cp Release/* /c/zlib/
fi

cd $DIR
if [ ! -e FreeGLUT/build ]; then
	echo "compile freeglut"
	mkdir FreeGLUT/build
	cd FreeGLUT/build
	cmake -G "$VSgenerator" ../freeglut/freeglut
	cmake --build . --config Release
	mkdir /c/freeglut
	cp bin/Release/* /c/freeglut/
	cp lib/Release/* /c/freeglut/
	cp *.h /c/freeglut/
	cp -r ../freeglut/freeglut/include/* /c/freeglut/
fi

cd $DIR
if [ ! -e OpenSG/build ]; then
	echo "compile opensg"
	mkdir OpenSG/build
	cd OpenSG/build
	cmake -G "$VSgenerator" -DOSGBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DGLUT_INCLUDE_DIR="/c/freeglut" -DGLUT_glut_LIBRARY_RELEASE="/c/freeglut/freeglut.lib" -DZLIB_INCLUDE_DIR="/c/zlib" -DZLIB_LIBRARY_RELEASE="/c/zlib/zlib.lib" -DBoost_FILESYSTEM_LIBRARY_RELEASE="/c/boost/lib64-msvc-14.1/boost_filesystem-vc141-mt-1_65_1.lib" -DBoost_SYSTEM_LIBRARY_RELEASE="/c/boost/lib64-msvc-14.1/boost_system-vc141-mt-1_65_1.lib" ..
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