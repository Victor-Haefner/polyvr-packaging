#!/bin/bash

# check for root rights
if [ `whoami` != root ]; then
echo This script needs root permissions
exit 5
fi

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

function makeDir {
	local directory="$1"

	if [ ! -d "$directory" ]; then
		su $SUDO_USER -c "mkdir -p $directory"
		ls -la "$directory"
	fi
}

function setupHomebrew {
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"\n
	(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/victorhafner/.zprofile
}

function setupBasics {
	su $SUDO_USER -c "brew install cmake xquartz boost@1.76 uriparser"
	su $SUDO_USER -c "defaults write org.xquartz.X11 enable_iglx -bool true" # enable OpenGL with XQuartz
	su $SUDO_USER -c "softwareupdate --install-rosetta" # to run glxinfo for example
	makeDir "$DIR/repositories"
}

function cloneRepo {
	local directory="$1"
	local repo_url="$2"

	if [ ! -d "$directory" ]; then
		su $SUDO_USER -c "git clone \"$repo_url\" \"$directory\""
	else
		echo "Directory $directory already exists. Skipping cloning."
	fi
}

function compileFreeglut {
	cd "$DIR/repositories"
	cloneRepo freeglut https://github.com/Victor-Haefner/freeglut.git
	rm -rf freeglut/build
	makeDir freeglut/build
	cd freeglut/build
	su $SUDO_USER -c "cmake .. -DFREEGLUT_BUILD_DEMOS=OFF  -DOPENGL_gl_LIBRARY=/opt/X11/lib/libGL.dylib"
	su $SUDO_USER -c "make -j4"
	make install
}

function compileCollada {
	cd "$DIR/repositories"
	cloneRepo collada https://github.com/Victor-Haefner/collada-dom.git
	rm -rf collada/build
	makeDir collada/build
	cd collada/build
  local daeOpts="-DOPT_USE_PCRECPP=ON -DOPT_COLLADA15=OFF"
	su $SUDO_USER -c "cmake .. -DCMAKE_BUILD_TYPE=Release -DBOOST_ROOT=/opt/homebrew/opt/boost@1.76 $daeOpts"
	su $SUDO_USER -c "make -j4"
	make install
}

function compileOpenSG {
	cd "$DIR/repositories"
	cloneRepo opensg https://github.com/Victor-Haefner/OpenSGDevMaster.git
	rm -rf opensg/build
	makeDir opensg/build
	cd opensg/build
	local osgFlags="-DOSG_ENABLE_QHULL=OFF -DOSG_SHADER_CACHE_MODE=0 -DOSGBUILD_TESTS=OFF -DOSGBUILD_OSGContribCgFX=0 -DOSGBUILD_OSGContribCSM=0 -DOSGBUILD_OSGContribCSMSimplePlugin=0 -DCMAKE_CXX_STANDARD=11"
	local osgGlut="-DGLUT_FOUND=YES -DGLUT_INCLUDE_DIR=/usr/local/include -DGLUT_LIBRARIES=/usr/local/lib/libglut.dylib"
	local osgDae="-DCOLLADA_LIBRARY_RELEASE=/usr/local/lib/libcollada-dom2.5-dp.dylib -DCOLLADA_DAE_INCLUDE_DIR=/usr/local/include/collada-dom2.5 -DCOLLADA_DOM_INCLUDE_DIR=/usr/local/include/collada-dom2.5/1.4 -DOSG_WITH_COLLADA_NAMESPACE=ON"
	local osgBoost="-DBOOST_ROOT=/opt/homebrew/opt/boost@1.76"
	su $SUDO_USER -c "cmake .. -Wno-dev  -DCMAKE_BUILD_TYPE=Release $osgFlags $osgGlut $osgDae $osgBoost"
	su $SUDO_USER -c "make -j4"
	make install
}

function compileCEF {
	su $SUDO_USER -c "brew install python@3.9"
	export PYTHON_EXECUTABLE="/opt/homebrew/bin/python3.9" # cef scripts break with python 3.12

	cd "$DIR/repositories"
	cloneRepo cef https://github.com/chromiumembedded/cef-project.git
	rm -rf cef/build
	makeDir cef/build
	cd cef/build
	cmake
	su $SUDO_USER -c "cmake -DPROJECT_ARCH='arm64' -DUSE_SANDBOX=Off -DWITH_EXAMPLES=Off -DWITH_TESTS=Off .."
	su $SUDO_USER -c "make -j4" # will fail when building the tests.. just ignore or add optiojn to cmakelists..

	mkdir /usr/local/include/cef
	mkdir /usr/local/lib/cef
	cd $DIR/repositories/cef
	cp -r third_party/cef/*/include /usr/local/include/cef/
	cp -r build/Release/* /usr/local/lib/cef/
	cp -r build/libcef_dll_wrapper/*.a /usr/local/lib/cef/
  cp -r third_party/cef/*/Release/* /usr/local/lib/cef/
}


function setupPolyVRDependencies {
	brew install pyenv
	pyenv install 2.7.18
	pyenv global 2.7.18
	PATH=$(pyenv root)/shims:$PATH

	brew install bullet
	brew install ffmpeg
	brew install openal-soft
	brew install lapack eigen
	brew install fftw
	brew install libomp
	brew install jsoncpp
	brew install gdal
}

# Up-to-date: /usr/local/lib/libglut.dylib
#- Installing: /usr/local/lib/libglut.a
#-- Up-to-date: /usr/local/include/GL/freeglut.h

#setupHomebrew
#setupBasics
eval "$(/opt/homebrew/bin/brew shellenv)"
export DYLD_LIBRARY_PATH="/usr/local/lib:$DYLD_LIBRARY_PATH"
export C_INCLUDE_PATH="/usr/local/include:/opt/X11/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="/usr/local/include:/opt/X11/include:$CPLUS_INCLUDE_PATH"
#compileFreeglut
compileCollada
#compileOpenSG
#compileCEF
#setupPolyVRDependencies
