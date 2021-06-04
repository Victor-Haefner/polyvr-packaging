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

if [ ! -e polyvr/build/polyvr.wasm ]; then
	echo "did not find polyvr/build/polyvr.wasm, maybe compilation failed?"
	exit 0
fi

if [ ! -e polyvr/build/polyvr.js ]; then
	echo "did not find polyvr/build/polyvr.js, maybe compilation failed?"
	exit 0
fi

cp polyvr/build/polyvr.wasm webBuild/
cp polyvr/build/polyvr.js webBuild/

cd webBuild
./hack_polyvr_js.sh
