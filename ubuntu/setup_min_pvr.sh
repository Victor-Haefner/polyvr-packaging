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

apt-get update
pvrdep="pvr_dependencies_min"

while read line
do
apt-get -fy install $line > /dev/null
if [ $? == 0 ]; then
echo " " $line installed
fi
done <$pvrdep

#install FMOD
mkdir /usr/local/include/fmodex
ln -s $DIR/FMOD/api/inc/* /usr/local/include/fmodex
ln -s $DIR/FMOD/api/lib/libfmodex64.so /usr/lib/libfmodex.so
