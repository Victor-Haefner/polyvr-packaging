@echo off

set myDir="%cd%"

echo --- init vcvars64 ---
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"

echo --- configure libxml2 ---
cd %myDir%
cscript configure.js compiler=msvc prefix=C:\usr include=C:\usr\include lib=C:\usr\lib debug=no iconv=no

rem set CL=/I%myDir%\..\os400\iconv

echo --- compile libxml2 --- 
nmake -f Makefile.msvc
nmake -f Makefile.msvc install