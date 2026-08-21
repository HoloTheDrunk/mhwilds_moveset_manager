#!/usr/bin/env sh

set -e

rm -rf "$WILDS_DIR/reframework/data/movesets"
cp -r examples "$WILDS_DIR/reframework/data/movesets"

cd src
lua compiler.lua
mv output.lua "$WILDS_DIR/reframework/autorun/moveset_manager.lua"
cd -
