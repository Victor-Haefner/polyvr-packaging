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
cd $DIR

# for gtk3
# install the meson build system
#  download msi package from https://github.com/mesonbuild/meson/releases
#  download python3 installer https://www.python.org/downloads/release/python-382/

libDir="/c/usr/lib"
incDir="/c/usr/include"

# TODO: move functions to own file!
function makeDir {
	if [ ! -e $1 ]; then
		mkdir -p $1 
	fi
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

makeDir $libDir
makeDir $incDir
makeDir base
makeDir gtk

# TODO: move base to own setup file!
downloadRepository base/libpng --branch libpng16 https://github.com/glennrp/libpng.git
downloadRepository base/libjpeg --branch 1.5.x https://github.com/libjpeg-turbo/libjpeg-turbo.git
downloadRepository base/libpixman --branch 0.34 https://github.com/aseprite/pixman.git
downloadRepository base/libexpat --branch R_2_2_53 https://github.com/libexpat/libexpat.git
downloadRepository base/libfontconfig --branch 2.12.6 https://github.com/freedesktop/fontconfig.git
downloadRepository base/libpcre	--branch pcre-8.36 https://github.com/vmg/libpcre.git # 2:8.39-9
downloadRepository base/libffi --branch v3.2.1 https://github.com/libffi/libffi.git
downloadRepository base/libicu --branch release-60-2 https://github.com/unicode-org/icu.git

downloadRepository gtk/libpango --branch 1.40.14 https://gitlab.gnome.org/GNOME/pango.git
downloadRepository gtk/libgdkpixbuf --branch 2.36.11 https://gitlab.gnome.org/GNOME/gdk-pixbuf.git
downloadRepository gtk/libglib2 --branch glib-2-56 https://gitlab.gnome.org/GNOME/glib.git
downloadRepository gtk/libatk --branch ATK_2_28_1 https://gitlab.gnome.org/GNOME/atk.git
downloadRepository gtk/libgtk2 --branch 2.24.32 https://gitlab.gnome.org/GNOME/gtk.git
downloadRepository gtk/libgtksourceview --branch gnome-2-30 https://gitlab.gnome.org/GNOME/gtksourceview.git
downloadRepository gtk/libgtkglext https://github.com/Distrotech/gtkglext.git

#./compile_gtk







