#!/bin/bash

if [[ "$2" = "" ]]; then
  echo "$0 <error.txt> <source_dir>"
  exit 1
fi

escape() {
  sed -e 's/\([[\/.*]\|\]\)/\\&/g'
}

grep -i "Warning: Io: Error" "$1" | while read line; do
  file="$(echo "$line" | cut -d ':' -f4 | cut -d ' ' -f3)"
  src="$2/$file"
  if [[ -f "$src" ]]; then
    call="$(echo "$line" | cut -d ':' -f5)"
    call=${call# *}
    call=${call% *}
    call="$(echo "$call" | escape)"
    echo "Fix: $src"
    sed -i "/REM REMOVED_BY_BASH/! s/$call/REM REMOVED_BY_BASH $call/g" "$src"
    [[ "$OS" = "Windows_NT" ]] && attrib -r -a "$src"
    #cat "$src"
    #exit
  else
    echo "WARNING: File '$src' does not exist"
  fi
done
