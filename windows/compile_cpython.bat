@echo off

set myDir="%cd%"

echo --- init vcvars64 ---
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"

echo --- compile cpython --- 
cd %myDir%
rem https://stackoverflow.com/questions/43704734/how-to-fix-the-error-windows-sdk-version-8-1-was-not-found
build.bat "/p:Platform=x64" "/p:PlatformToolset=v141"

rem Not automated: 
rem  open pythoncore.vcxproj in Visual Studio, is will ask you to retarget, accept
