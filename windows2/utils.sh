#!/bin/bash

function getExecutionDir {
	SOURCE="${BASH_SOURCE[0]}"
	DIR="$( dirname "$SOURCE" )"
	while [ -h "$SOURCE" ]
	do 
	  SOURCE="$(readlink "$SOURCE")"
	  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
	  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
	done
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	echo $DIR
}

function downloadRepository {
	cd $DIR
	if [ ! -e $1 ]; then
		echo "download $1 source"
		git clone ${@:2} $1
	else
		echo "$1 source allready present"
	fi
}

function mkDir {
	if [ ! -e $1 ]; then 
		mkdir -p $1 
	fi
}

function getGenerator {
	echo "Visual Studio 15 2017 Win64"
	#echo "Visual Studio 16 2019"
}
