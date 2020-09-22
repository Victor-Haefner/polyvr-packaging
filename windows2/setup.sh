#!/bin/bash

# TODOs
#  newer CMAKE
#  add COLLADA 
#  fix PNG and glew
#  automate generator

source utils.sh

DIR=$(getExecutionDir)
GENERATOR=$(getGenerator)

echo "Running windows polyvr build setup in $DIR"
echo " Compiling for $GENERATOR"

libDir="/c/usr/lib"
incDir="/c/usr/include"
vcpkgDir="/c/usr/vcpkg"

mkDir $libDir
mkDir $incDir

downloadRepository $vcpkgDir https://github.com/Microsoft/vcpkg.git
downloadRepository repositories/opensg https://github.com/Victor-Haefner/OpenSGDevMaster.git
downloadRepository repositories/polyvr https://github.com/Victor-Haefner/polyvr.git


# ------------------------------------- install basic dependencies ----------------------------------------
cd $vcpkgDir

if [ ! -e vcpkg.exe ]; then
	git checkout ee17a685087a6886e5681e355d36cd784f0dd2c8
	./bootstrap-vcpkg.bat
fi

./vcpkg.exe install zlib:x64-windows          # find_package(ZLIB REQUIRED)                 target_link_libraries(main PRIVATE ZLIB::ZLIB)
./vcpkg.exe install libpng:x64-windows        # find_package(libpng CONFIG REQUIRED)        target_link_libraries(main PRIVATE png)
./vcpkg.exe install libjpeg-turbo:x64-windows # find_package(JPEG REQUIRED)                 target_link_libraries(main PRIVATE ${JPEG_LIBRARIES})         target_include_directories(main PRIVATE ${JPEG_INCLUDE_DIR})
./vcpkg.exe install libxml2:x64-windows       # find_package(LibXml2 REQUIRED)              target_link_libraries(main PRIVATE ${LIBXML2_LIBRARIES})      target_include_directories(main PRIVATE ${LIBXML2_INCLUDE_DIR})
./vcpkg.exe install freetype:x64-windows      # find_package(freetype CONFIG REQUIRED)      target_link_libraries(main PRIVATE freetype)
./vcpkg.exe install tiff:x64-windows 
./vcpkg.exe install gdal:x64-windows 
./vcpkg.exe install freeglut:x64-windows      # find_package(GLUT REQUIRED)                 target_link_libraries(main PRIVATE GLUT::GLUT)
./vcpkg.exe install python2:x64-windows
./vcpkg.exe install boost:x64-windows
./vcpkg.exe install glew:x64-windows
./vcpkg.exe integrate install


# ------------------------------------- compile OpenSG ----------------------------------------
rm -rf $DIR/repositories/opensg/build

cd $DIR/repositories
if [ ! -e opensg/build ]; then
	echo "compile opensg"
	mkdir opensg/build
	cd opensg/build
#	cmake -G "$GENERATOR" -DOSGBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DBOOST_INCLUDEDIR="$DIR/repositories/vcpkg/installed/x86-windows/include" -DBoost_FILESYSTEM_LIBRARY_RELEASE="/c/boost/lib64-msvc-14.1/boost_filesystem-vc141-mt-1_65_1.lib" -DBoost_SYSTEM_LIBRARY_RELEASE="/c/boost/lib64-msvc-14.1/boost_system-vc141-mt-1_65_1.lib" -DGLUT_INCLUDE_DIR="/c/freeglut" -DGLUT_glut_LIBRARY_RELEASE="/c/freeglut/freeglut.lib" -DZLIB_INCLUDE_DIR="/c/zlib" -DZLIB_LIBRARY_RELEASE="/c/zlib/zlib.lib" ..
	cmake -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DOSGBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ..
	
	
	
	cmake --build . --config Release
	d_inc=$incDir/OpenSG/
	mkdir -p $d_inc

	cd $DIR/repositories/opensg
	find Source -name "*.h" -exec cp {} $d_inc \;
	find Source -name "*.inl" -exec cp {} $d_inc \;
	find build/Source -name "*.h" -exec cp {} $d_inc \;
	cp Source/WindowSystem/X/OSGNativeWindow.h $d_inc
	cp -r build/bin/Release/* $libDir/opensg/
fi



