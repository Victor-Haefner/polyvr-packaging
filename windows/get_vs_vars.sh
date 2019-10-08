#!/bin/bash

source set_variables.sh

echo "Start installation of dependencies for PolyVR"
echo " which VS Version? (2017/2019/..)"

read VSversion
VSgenerator="Visual Studio 15 2017 Win64"

if [ $VSversion == "2019" ]; then
VSgenerator="Visual Studio 16 2019"
fi

export VSCMD_START_DIR=$DIR
/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/$VSversion/Community/VC/Auxiliary/Build/vcvarsall.bat x86_amd64