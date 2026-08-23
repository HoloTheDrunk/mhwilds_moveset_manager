#!/usr/bin/env sh

dir="$(dirname "$0")"
buf="$(mktemp)"

ko=0
ok=0
while read -r line; do
  echo -en "\033[1;33mTESTING\033[0m: $line"
  cat "$line" | lua -e "package.path=\"$dir/src/?.lua;\"..package.path" "$dir/src/parser.lua" --stdin >"$buf" 2>"$buf"
  if [ $? = 0 ]; then
    echo -e "\r\033[1;32m     OK\033[0m"
    ok=$((ok + 1))
  else
    echo -e "\r\033[1;31m     KO\033[0m"
    cat "$buf"
    ko=$((failures + 1))
  fi
done <<< "$(find examples -name '*.moveswap')"

echo -e "\033[1;32mOK\033[0m: $ok"
echo -e "\033[1;31mKO\033[0m: $ko"
