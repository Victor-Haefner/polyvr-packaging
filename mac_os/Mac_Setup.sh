#!/bin/bash

##
# For Mac OS 10.7.04 Lion :
# Needs :
# Macports : http://www.macports.org/install.php
# Sudo permission
##

port selfupdate
port upgrade outdated

#Dependencies (from Ogre3d)

port install libpng +universal jpeg +universal libxml2 +universal
port install pkgconfig xmlto autoconf automake libtool
port install freetype +universal freeimage +universal libzzip +universal boost +universal ois +universal
port install cmake

#Dependencies for OpenSG 2.x (specific)
port install collada-dom fontconfig libxmlxx2

#For our framework
port install gtk2

port selfupdate
port upgrade outdated

## TODO : say to cmake where are Boost and Collada.


#apt-get install glade-gnome libvte-dev blender git cmake build-essential libboost-dev zlib1g-dev libjpeg8-dev libjpeg-dev libfreetype6-dev libtiff4-dev libpng12-dev libgif-dev freeglut3-dev libgdal1-dev libboost-filesystem-dev libvtk5-dev doxygen python-dev nvidia-cg-toolkit libboost-python-dev libxi-dev libxmu-dev codeblocks libboost-program-options-dev libboost-thread-dev libxml++2.6-dev libcolladadom-dev python-gtkglext1 python-vte opencl-headers alacarte

mkdir ~/Downloads/OpenSG
cd ~/Downloads/OpenSG
git clone git://opensg.git.sourceforge.net/gitroot/opensg/opensg
cd opensg
mkdir build
cd build
cmake ..
make && make install
ln /usr/local/lib/debug/* /opt/local/lib/
ln /usr/local/lib64/debug/* /opt/local/lib/
cd ~/Downloads/OpenSG/opensg/Examples/Tutorial
mkdir build
cd build
cmake ..
make

#clone repo with
#git clone git@imizeus.imi.uni-karlsruhe.de:VRFramework
#cd VRFramework
#git clone git@imizeus.imi.uni-karlsruhe.de:VRData data

#trac:
#http://imizeus.imi.uni-karlsruhe.de/trac/PolyVR/

#http://www.opensg.org/wiki/Building

#Bullets: (download and extract)
#mkdir build
#cd build
#cmake .. -G "Unix Makefiles"
#make
#sudo make install
