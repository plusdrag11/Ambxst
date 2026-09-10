#!/bin/sh
# Compile wallpaper transition shaders to .qsb.
#
# The shell QML runs uncompiled (no qrc), so the .qsb files are committed
# alongside their .frag sources. Whenever a .frag changes, rerun this script
# and commit the regenerated .qsb with it.
#
# qsb ships with qt6-shadertools (kdePackages.qtshadertools in the dev shell);
# it is typically not on PATH.
set -eu

cd "$(dirname "$0")/.."

QSB=${QSB:-$(command -v qsb || echo /usr/lib/qt6/bin/qsb)}

for f in modules/widgets/dashboard/wallpapers/transitions/*.frag; do
    "$QSB" --glsl "300es,330" --hlsl 50 --msl 12 -O -o "$f.qsb" "$f"
    echo "compiled $f.qsb"
done
