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

# auxilliary function to add a ppa only if it exists
add_ppa() {
  grep -h "^deb.*$1" /etc/apt/sources.list.d/* > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    echo "Adding ppa:$1"
    add-apt-repository -y ppa:$1
    return 0
  fi

  echo "ppa:$1 already exists"
  return 1
}

if [ $JOB == "ALL" ]; then
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
  cmake .. && make -j4 && make install
fi
fi

# compile VRPN
if [ $JOB == "ALL" ] || [ $JOB == "VRPN" ]; then
cd $DIR
if [ ! -e VRPN/.git ]; then
  cd ../../../
  su $SUDO_USER -c "git submodule update --init $DIR/VRPN"
fi

cd $DIR
if [ ! -e VRPN/build ]; then
  su $SUDO_USER -c "mkdir -p VRPN/build"
  cd VRPN/build
  cmake .. && make -j4 && make install
fi
fi

# get OpenSG source from git
if [ $JOB == "ALL" ] || [ $JOB == "OSG" ]; then
cd $DIR
if [ ! -e OpenSG/.git ]; then
  cd ../../../
  su $SUDO_USER -c "git submodule update --init $DIR/OpenSG"
fi

# install OpenSG
cd $DIR
if [ ! -e OpenSG/build ]; then
  su $SUDO_USER -c "mkdir OpenSG/build"
  cd OpenSG/build
  cmake .. -DOSGBUILD_TESTS=OFF && make -j4 && make install
  #tutorials
  cd ../Examples/Tutorial
  su $SUDO_USER -c "mkdir build"
  cd build
  cmake -DCMAKE_MODULE_PATH=/usr/local/share/OpenSG/cmake -DOPENSG_LIBRARY_DIR=/usr/local/lib64/debug .. && make
fi
fi