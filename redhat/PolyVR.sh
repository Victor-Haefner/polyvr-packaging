#!/bin/bash
LC_ALL=C
SOURCE="${BASH_SOURCE[0]}"
DIR="$( dirname "$SOURCE" )"
while [ -h "$SOURCE" ]
do 
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

if [ ! -e ~/.polyvr ]; then
  cp -r /usr/share/polyvr ~/.polyvr
fi
cd ~/.polyvr

libs=/usr/lib/opensg:/usr/lib/CEF
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$libs && polyvr-bin
