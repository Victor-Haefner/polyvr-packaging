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
./setup_emsdk.sh

cd $DIR
./setupOSG.sh

cd $DIR
./setupPVR.sh

cd $DIR
./deployWasm.sh