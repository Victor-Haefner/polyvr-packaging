#!/bin/bash

# check for root rights
if [ `whoami` != root ]; then
echo This script needs root permissions
exit 5
fi

# set default job to all
JOB=$1
if [ "$JOB" == "" ]; then
JOB="ALL"
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

if [ $JOB == "ALL" ] || [ $JOB == "LIBS" ]; then
#add_ppa irie/blender #Blender
#add_ppa blk/ppa #Bullets
#add_ppa panda3d/ppa #FMOD
#add_ppa barthelemy/collada #Collada
apt-get update

osgdep="osg_dependencies"
pvrdep="pvr_dependencies"

while read line
do
apt-get -fy install $line > /dev/null
if [ $? == 0 ]; then
echo " " $line installed
fi
done <$osgdep

while read line
do
apt-get -fy install $line > /dev/null
if [ $? == 0 ]; then
echo " " $line installed
fi
done <$pvrdep
fi

# compile COLLADA
if [ $JOB == "ALL" ] || [ $JOB == "COLLADA" ]; then
cd $DIR
if [ ! -e collada-dom/build ]; then
  su $SUDO_USER -c "mkdir -p collada-dom/build"
  cd collada-dom/build
  cmake -DCMAKE_BUILD_TYPE=Release .. && make -j4 && make DESTDIR=./install install
fi
fi

# compile VRPN
if [ $JOB == "ALL" ] || [ $JOB == "VRPN" ]; then
cd $DIR
if [ ! -e VRPN/.git ]; then
  #su $SUDO_USER -c "git clone git://git.cs.unc.edu/vrpn.git $DIR/VRPN"
  su $SUDO_USER -c "git clone https://github.com/vrpn/vrpn.git $DIR/VRPN"
  su $SUDO_USER -c "cd $DIR/VRPN && git submodule update --init"
fi

cd $DIR
if [ ! -e VRPN/build ]; then
  su $SUDO_USER -c "mkdir -p VRPN/build"
  cd VRPN/build
  cmake -DCMAKE_BUILD_TYPE=Release -DVRPN_USE_HID=TRUE -DHIDAPI_INCLUDE_DIR="/usr/include/hidapi" -DHIDAPI_LIBRARY="/usr/lib/x86_64-linux-gnu/libhidapi-libusb.so" .. && make -j4
fi
fi

# get OpenSG source from git
if [ $JOB == "ALL" ] || [ $JOB == "OSG" ]; then
cd $DIR
if [ ! -e OpenSG/.git ]; then
  #su $SUDO_USER -c "git clone git://git.code.sf.net/p/opensg/code $DIR/OpenSG"
  su $SUDO_USER -c "git clone https://github.com/Victor-Haefner/OpenSGDevMaster.git $DIR/OpenSG"
fi

# compile OpenSG
cd $DIR
if [ ! -e OpenSG/build ]; then
  su $SUDO_USER -c "mkdir OpenSG/build"
  cd OpenSG/build
  cmake -DOSG_ENABLE_QHULL=OFF -DOSG_SHADER_CACHE_MODE=0 -DOSGBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DCOLLADA_LIBRARY_RELEASE=../../collada-dom/build/install/usr/local/lib/libcollada14dom.so -DCOLLADA_DAE_INCLUDE_DIR=../../collada-dom/build/install/usr/local/include/collada-dom -DCOLLADA_DOM_INCLUDE_DIR=../../collada-dom/build/install/usr/local/include/collada-dom/1.4 .. && make -j4
fi
fi

# get STEPcode source from git
if [ $JOB == "ALL" ] || [ $JOB == "STEP" ]; then
cd $DIR
if [ ! -e STEPcode/.git ]; then
  su $SUDO_USER -c "git clone https://github.com/stepcode/stepcode.git $DIR/STEPcode"
fi

# compile STEPcode
cd $DIR
if [ ! -e STEPcode/build ]; then
  su $SUDO_USER -c "mkdir STEPcode/build"
  cd STEPcode/build
  cmake -DSC_BUILD_SCHEMAS=ap214e3  -DCMAKE_BUILD_TYPE=Release .. && make -j4 && make sdai_ap214e3
fi
fi

# get IFC source from git
if [ $JOB == "ALL" ] || [ $JOB == "IFC" ]; then
cd $DIR
if [ ! -e IFC/.git ]; then
  su $SUDO_USER -c "git clone https://github.com/Victor-Haefner/IfcOpenShell.git $DIR/IFC"
fi

# compile IFC
cd $DIR
if [ ! -e IFC/build ]; then
  su $SUDO_USER -c "mkdir IFC/build"
  cd IFC/build
  cmake ../cmake -DOCC_LIBRARY_DIR=/usr/lib/x86_64-linux-gnu/ -DCOLLADA_SUPPORT=0 -DBUILD_IFCPYTHON=0 -DPCRE_LIBRARY_DIR=/usr/lib/x86_64-linux-gnu/ && make -j4
fi
fi

# get OPCUA source from git
if [ $JOB == "ALL" ] || [ $JOB == "OPCUA" ]; then
cd $DIR
if [ ! -e OPCUA/.git ]; then
  su $SUDO_USER -c "git clone https://github.com/Victor-Haefner/freeopcua.git $DIR/OPCUA"
fi

# compile OPCUA
cd $DIR
if [ ! -e OPCUA/build ]; then
  su $SUDO_USER -c "mkdir OPCUA/build"
  cd OPCUA/build
  cmake -DSSL_SUPPORT_MBEDTLS=OFF .. && make -j4
fi
fi
