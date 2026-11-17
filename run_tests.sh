#!/usr/bin/env bash

dir="$(dirname "$0")"
buf="$(mktemp)"

cd "$dir/src"

# Test suite
DEBUG=1 lua test/core.lua
# ! Test suite

if [ $? -ne 0 ]; then
  echo "Skipping remaining tests..."
  cd - >/dev/null
  exit $?
fi

# Examples
ko=0
ok=0
while read -r line; do
  echo -en "\033[1;33mTESTING\033[0m: $line"
  cat "$line" | lua -e "package.path=\"$dir/src/?.lua;\"..package.path" "lib/parser.lua" --stdin >"$buf" 2>"$buf"
  if [ $? = 0 ]; then
    echo -e "\r\033[1;32m     OK\033[0m"
    ok=$((ok + 1))
  else
    echo -e "\r\033[1;31m     KO\033[0m"
    cat "$buf"
    ko=$((ko + 1))
  fi
done <<< "$(find ../examples -name '*.moveswap')"

echo -e "\033[1;32mOK\033[0m: $ok"
echo -e "\033[1;31mKO\033[0m: $ko"
# ! Examples

cd -
