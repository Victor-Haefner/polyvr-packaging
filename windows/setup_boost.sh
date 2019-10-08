#!/bin/bash

# get boost -> TODO
#  download boost binaries, see wiki on github!
#  https://sourceforge.net/projects/boost/files/boost-binaries/1.65.1/boost_1_65_1-msvc-14.1-64.exe/download
#  install in C:\boost   !!!!!

export BOOST_INCLUDEDIR="/c/boost"
export BOOST_ROOT="/c/boost"
export Boost_FILESYSTEM_LIBRARY_Debug="/c/boost/lib64-msvc-14.1/boost_filesystem-vc141-mt-1_65_1.dll"
export Boost_FILESYSTEM_LIBRARY_RELEASE="/c/boost/lib64-msvc-14.1/boost_filesystem-vc141-mt-1_65_1.dll"
export Boost_SYSTEM_LIBRARY_Debug="/c/boost/lib64-msvc-14.1/boost_system-vc141-mt-1_65_1.dll"
export Boost_SYSTEM_LIBRARY_RELEASE="/c/boost/lib64-msvc-14.1/boost_system-vc141-mt-1_65_1.dll"