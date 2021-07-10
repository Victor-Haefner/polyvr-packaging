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

if [ ! -e webBuild ]; then
	git clone https://github.com/Victor-Haefner/polyvr-webport.git webBuild
fi

copyFile() {
	if [ ! -e $1 ]; then
		echo "did not find polyvr $1, maybe compilation failed?"
		exit 0
	fi

	cp $1 webBuild/
}

copyFile polyvr/build/polyvr.wasm
copyFile polyvr/build/polyvr.js
copyFile include/libproj/proj.db

cd webBuild
./hack_polyvr_js.sh
