#!/usr/bin/env sh

[ $# -lt 1 ] && echo "Usage: ./archive.sh <version>" && exit 1
VERSION="$1"
FOLDER_NAME="moveset_manager_v$VERSION"

[ ! -d "artefacts" ] && mkdir artefacts

cd artefacts/

mkdir -p tmp/reframework/autorun
cp ../moveset_manager.lua tmp/reframework/autorun

cat > tmp/modinfo.ini <<EOF
name=Moveset Manager
version=$VERSION
description=Manages moveset swaps.
screenshot=nexus_banner.png
category=Gameplay
author=HoloTheSober
EOF

cp ../screenshots/nexus_banner.png tmp/

mkdir tmp/reframework/data
cp -r ../examples tmp/reframework/data/movesets

mv tmp "$FOLDER_NAME"
[ -e "moveset_manager.zip" ] && rm moveset_manager.zip
zip -r moveset_manager.zip "$FOLDER_NAME"
rm -rf "$FOLDER_NAME"

cd -
