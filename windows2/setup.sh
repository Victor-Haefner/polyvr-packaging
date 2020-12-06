#!/bin/bash

# !before you launch this script!
#  install Visual Studio 2019
#  install python 3.8

# TODO
#  after first run of the cef cmake stuff
#   change /MT to /MD in
#    third_party/cef/cef_binary_81.2.24+gc0b313d+chromium-81.0.4044.113_windows64/cmake/cef_variables.cmake

source utils.sh

DIR=$(getExecutionDir)
GENERATOR=$(getGenerator)
echo "Running windows polyvr build setup in $DIR"
echo " Build generator: $GENERATOR"


# change the disk as required
rootDir="/d"
if [ ! -e $rootDir ]; then
	rootDir="/c"
fi


libDir="$rootDir/usr/lib"
incDir="$rootDir/usr/include"
vcpkgDir="$rootDir/usr/vcpkg"
vcpkgIncDir="$vcpkgDir/installed/x64-windows/include"
vcpkgLibDir="$vcpkgDir/installed/x64-windows/lib"

mkDir $libDir
mkDir $incDir

downloadRepository $vcpkgDir https://github.com/Microsoft/vcpkg.git
downloadRepository repositories/cef https://github.com/chromiumembedded/cef-project.git
downloadRepository repositories/opensg https://github.com/Victor-Haefner/OpenSGDevMaster.git
downloadRepository repositories/openvr https://github.com/ValveSoftware/openvr.git
downloadRepository repositories/collada https://github.com/Victor-Haefner/collada-dom.git
downloadRepository repositories/polyvr https://github.com/Victor-Haefner/polyvr.git
downloadRepository repositories/oce https://github.com/Victor-Haefner/oce.git
downloadRepository repositories/ifc https://github.com/Victor-Haefner/IfcOpenShell.git


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
./vcpkg.exe install cgal:x64-windows 
./vcpkg.exe install freeglut:x64-windows      # find_package(GLUT REQUIRED)                 target_link_libraries(main PRIVATE GLUT::GLUT)
./vcpkg.exe install python2:x64-windows
./vcpkg.exe install boost:x64-windows
./vcpkg.exe install glew:x64-windows
#./vcpkg.exe install collada-dom:x64-windows   # segfaults in DAE::open
./vcpkg.exe install bullet3:x64-windows
./vcpkg.exe install gtk:x64-windows

# when using vcpkg collada
#cp buildtrees/collada-dom/x64-windows-rel/dom/src/1.4/colladadom141.lib $vcpkgLibDir/
#cp buildtrees/collada-dom/x64-windows-rel/dom/src/1.5/colladadom150.lib $vcpkgLibDir/

cmakeExe=$vcpkgDir/$(find ./downloads/tools -name cmake.exe)
echo " using cmake: $cmakeExe"

# ------------------------------------- compile COLLADA ----------------------------------------
#rm -rf $DIR/repositories/collada/build

cd $DIR/repositories
if [ ! -e collada/build ]; then
	echo "compile collada"
	mkdir collada/build
	cd collada/build
	
	$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DCMAKE_BUILD_TYPE=Release -DOPT_COLLADA15=OFF ..
	$cmakeExe --build . --config Release

	d_inc=$incDir/Collada/
	mkdir -p $d_inc
	mkdir -p $libDir/collada

	cd $DIR/repositories/collada
	cp -r dom/include/* $d_inc/
	cp -r build/dom/Release/* $libDir/collada/
	cp build/dom/src/1.4/Release/* $libDir/collada/

fi

# ------------------------------------- compile OpenSG ----------------------------------------
#rm -rf $DIR/repositories/opensg/build

cd $DIR/repositories
if [ ! -e opensg/build ]; then
	echo "compile opensg"
	mkdir opensg/build
	cd opensg/build
	
	# with vcpkg collada
	#$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DOSGBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DCOLLADA_DAE_INCLUDE_DIR=$vcpkgDir/installed/x64-windows/include/collada-dom2.5 -DCOLLADA_DOM_INCLUDE_DIR=$vcpkgDir/installed/x64-windows/include/collada-dom2.5/1.4 -DOSG_WITH_COLLADA_NAMESPACE=ON ..
	
	# with collada from repo
	$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DOSGBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DCOLLADA_DAE_INCLUDE_DIR=$incDir/Collada -DCOLLADA_DOM_INCLUDE_DIR=$incDir/Collada/1.4 -DCOLLADA_LIBRARY_RELEASE=$libDir/collada/collada-dom2.5-dp-vc100-mt.lib -DOSG_WITH_COLLADA_NAMESPACE=ON ..
	$cmakeExe --build . --config Release

	d_inc=$incDir/OpenSG/
	mkdir -p $d_inc
	mkdir -p $libDir/opensg

	cd $DIR/repositories/opensg
	find Source -name "*.h" -exec cp {} $d_inc \;
	find Source -name "*.inl" -exec cp {} $d_inc \;
	find build/Source -name "*.h" -exec cp {} $d_inc \;
	cp Source/WindowSystem/X/OSGNativeWindow.h $d_inc
	cp -r build/bin/Release/* $libDir/opensg/
fi

# ------------------------------------- compile OpenVR ----------------------------------------
cd $DIR/repositories
if [ ! -e openvr/build ]; then
	echo "compile openvr"
	mkdir openvr/build
	cd openvr/build
	
	$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED=ON ..
	$cmakeExe --build . --config Release

	d_inc=$incDir/OpenVR/
	mkdir -p $d_inc
	mkdir -p $libDir/openvr

	cd $DIR/repositories/openvr
	cp headers/* $d_inc/
	cp bin/win64/Release/* $libDir/openvr/
fi

# ------------------------------------- compile CEF ----------------------------------------
#rm -rf $DIR/repositories/cef/build
	
cd $DIR/repositories
if [ ! -e cef/build ]; then
	echo "compile cef"
	mkdir cef/build
	cd cef/build
	
	$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake ..
	$cmakeExe --build . --config Release

	d_inc=$incDir/CEF/
	mkdir -p $d_inc
	mkdir -p $libDir/cef
	
	cd $DIR/repositories/cef
	cp -r third_party/cef/cef_binary_81.2.24+gc0b313d+chromium-81.0.4044.113_windows64/include $d_inc/;
	cp -r build/Release/* $libDir/cef/
	cp -r build/libcef_dll_wrapper/Release/* $libDir/cef/
	cp third_party/cef/cef_binary_81.2.24+gc0b313d+chromium-81.0.4044.113_windows64/Release/libcef.lib $libDir/cef/
fi
# TODO: copy pak files!

#rm -rf $DIR/repositories/polyvr/ressources/cefWin/build
cd $DIR/repositories/polyvr/ressources/cefWin
if [ ! -e build ]; then
	echo "compile cef subprocess executable"
	mkdir build
	cd build
	
	$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake ..
	$cmakeExe --build . --config Release
	cp Release/CefSubProcessWin.exe ../
fi

# ------------------------------------- compile OCE ----------------------------------------

cd $DIR/repositories
if [ ! -e oce/build ]; then
	echo "compile oce"
	mkdir oce/build
	cd oce/build
	
	
	$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DCMAKE_BUILD_TYPE=Release -DOCE_VISUALISATION=OFF -DOCE_DISABLE_TKSERVICE_FONT=ON..
	$cmakeExe --build . --config Release

	d_inc=$incDir/OCE/
	mkdir -p $d_inc
	mkdir -p $libDir/oce

	cd $DIR/repositories/oce
	cp -R inc/* $d_inc/
	cp src/*/*.h $d_inc/
	cp src/*/*.hxx $d_inc/
	cp src/*/*.lxx $d_inc/
	cp -r build/bin/Release/* $libDir/oce/
fi

# ------------------------------------- compile PolyVR ----------------------------------------
#rm -rf $DIR/repositories/polyvr/build

cd $DIR/repositories
if [ ! -e polyvr/build ]; then
	echo "compile polyvr"
	mkdir polyvr/build
	cd polyvr/build
	
	$cmakeExe -G "$GENERATOR" -DCMAKE_TOOLCHAIN_FILE=$vcpkgDir/scripts/buildsystems/vcpkg.cmake ..
	$cmakeExe --build . --config Release
fi










