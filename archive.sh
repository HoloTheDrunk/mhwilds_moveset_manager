#!/usr/bin/env sh

[ ! -d "artefacts" ] && mkdir artefacts

tar -czvf artefacts/moveset_manager.tar.gz moveset_manager.lua examples
zip -r artefacts/moveset_manager.zip moveset_manager.lua examples
rar a artefacts/moveset_manager.rar moveset_manager.lua examples
