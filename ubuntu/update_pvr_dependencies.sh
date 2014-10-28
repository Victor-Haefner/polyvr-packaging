#!/bin/sh

if [ `whoami` != root ]; then
echo This script needs root permissions
exit 5
fi

apt-get -fy update

pvrdep="$(dirname $0)/pvr_dependencies"

while read line
do
apt-get -fy install $line
done <$pvrdep

