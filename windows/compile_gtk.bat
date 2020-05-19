@echo off

set myDir="%cd%"

echo --- init vcvars64 ---
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"

rem meson does not handle correctly the recursive dependencies!
rem  run the meson command multiple times and copy the subprojects wrap files
rem   cp ./libgtk/subprojects/glib/subprojects/* ./libgtk/subprojects/
rem   cp ./libgtk/subprojects/pango/subprojects/* ./libgtk/subprojects/


rem meson .\libgtk\_build .\libgtk
rem ninja -C .\libgtk\_build
rem ninja -C .\libgtk\_build install

echo --- configure libgtk ---
cd %myDir%/libgtk2
nmake -f makefile.msc