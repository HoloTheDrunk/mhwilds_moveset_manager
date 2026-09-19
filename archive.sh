#!/usr/bin/env sh

set -e

start_dir="$(pwd)"

[ $# -lt 1 ] && echo "Usage: ./archive.sh <version>" >&2 && exit 1

# go to repo dir
cd "$(dirname "$0")"

VERSION="$1"
FOLDER_NAME="moveset_manager_v$VERSION"

# Generate single .lua file
cd src
lua compiler.lua
cd ..

[ ! -d artefacts ] && mkdir artefacts

cd artefacts

mkdir -p tmp/reframework/autorun
mv ../src/output.lua tmp/reframework/autorun/moveset_manager.lua

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

cd "$start_dir"
