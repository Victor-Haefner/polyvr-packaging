#!/bin/bash

# !before you launch this script!
#  install Visual Studio 2019


source utils.sh

DIR=$(getExecutionDir)
GENERATOR=$(getGenerator)
echo "Running windows polyvr build setup in $DIR"
echo " Build generator: $GENERATOR"

libDir="/c/usr/lib"
incDir="/c/usr/include"
vcpkgDir="/c/usr/vcpkg"
vcpkgIncDir="$vcpkgDir/installed/x64-windows/include"
vcpkgLibDir="$vcpkgDir/installed/x64-windows/lib"

mkDir $libDir
mkDir $incDir

downloadRepository $vcpkgDir https://github.com/Microsoft/vcpkg.git
downloadRepository repositories/opensg https://github.com/Victor-Haefner/OpenSGDevMaster.git
downloadRepository repositories/polyvr https://github.com/Victor-Haefner/polyvr.git


# ------------------------------------- install basic dependencies ----------------------------------------
cd $vcpkgDir

if [ ! -e vcpkg.exe ]; then
	./bootstrap-vcpkg.sh
fi

./vcpkg.exe integrate install
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
#./vcpkg.exe install collada-dom:x64-windows
./vcpkg.exe install gtk:x64-windows

cmakeExe=$vcpkgDir/$(find ./downloads/tools -name cmake.exe)
echo " using cmake: $cmakeExe"

# ------------------------------------- compile OpenSG ----------------------------------------
#rm -rf $DIR/repositories/opensg/build

d_inc=$incDir/OpenSG/
mkdir -p $d_inc
mkdir -p $libDir/opensg

cd $DIR/repositories
if [ ! -e opensg/build ]; then
	echo "compile opensg"
	mkdir opensg/build
	cd opensg/build
	
	#$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DOSGBUILD_TESTS=OFF -DCOLLADA_DAE_INCLUDE_DIR="$vcpkgIncDir/collada-dom2.5" -DCOLLADA_DOM_INCLUDE_DIR="$vcpkgIncDir/collada-dom2.5/1.5" -DCMAKE_BUILD_TYPE=Release ..
	
	$cmakeExe -G "$GENERATOR" -DBOOST_BIND_GLOBAL_PLACEHOLDERS -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DOSGBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ..

	$cmakeExe --build . --config Release

	cd $DIR/repositories/opensg
	find Source -name "*.h" -exec cp {} $d_inc \;
	find Source -name "*.inl" -exec cp {} $d_inc \;
	find build/Source -name "*.h" -exec cp {} $d_inc \;
	cp Source/WindowSystem/X/OSGNativeWindow.h $d_inc
	cp -r build/bin/Release/* $libDir/opensg/
fi
	


# ------------------------------------- compile PolyVR ----------------------------------------
#rm -rf $DIR/repositories/polyvr/build

cd $DIR/repositories
if [ ! -e polyvr/build ]; then
	echo "compile polyvr"
	mkdir polyvr/build
	cd polyvr/build
	$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=/c/usr/vcpkg/scripts/buildsystems/vcpkg.cmake ..
	$cmakeExe --build . --config Release
fi


#cd polyvr/build
#$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=/c/usr/vcpkg/scripts/buildsystems/vcpkg.cmake ..
#$cmakeExe --build . --config Release










