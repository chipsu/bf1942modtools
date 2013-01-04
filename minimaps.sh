#!/bin/bash

[[ "$2" != "" ]] || {
  echo "$0 <source> <dest>"
  exit
}

find "$1" -type f -iname 'ingamemap.dds' | sort | while read path; do
  mapname="$(dirname "$path")"
  mapname="$(dirname "$mapname")"
  mapname="$(basename "$mapname")"
  mapname="$(echo "$mapname" | tr '[A-Z]' '[a-z]')"
  echo "$path => $2/$mapname.dds"
  cp "$path" "$2/$mapname.dds"
done
