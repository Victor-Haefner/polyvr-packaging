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

# compile OpenSG
cd $DIR/OpenSG/build
make -j4

cd $DIR
./package_OPENSG true
gdebi -n libopensg-dev.deb
