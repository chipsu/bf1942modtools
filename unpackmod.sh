#!/bin/bash
shopt -s nocasematch

usage() {
  echo
  echo "  $(basename $0) [options] <source> <destination>"
  echo
  echo "    -t  rfaunpack executable"
  echo
}

verbose=0
compress=0
server=0
rfatool="$(dirname $0)/rfaunpack"

while getopts "t:" OPT; do
  case $OPT in
  t)
    rfatool="$OPTARG"
    ;;
  *)
    #echo "Error: -$OPTARG is not a valid option" >&2
    usage
    exit 1
    ;;
  esac
done

shift $(($OPTIND - 1))

[[ "$2" = "" ]] && {
  usage
  exit 1
}

src="$1"
dst="$2"

type "$rfatool" >/dev/null 2>&1 || {
  echo "Error: Could not find RFA binary '$1'" >&2
  usage
  exit 1
}

if [[ ! -d "$src" ]]; then
  echo "Error: Source '$src' does not exist" >&2
  usage
  exit 1
fi

echo
echo "$src => $dst"
echo

mkdir -p "$dst"

find "$src" -type f | sort | while read path; do
  file="${path#$src}"
  file="${file#*/}"
  file="$(echo "$file" | tr '[A-Z]' '[a-z]')"
  if [[ "$file" = *.rfa ]]; then
    echo "unpack $path => $dst"
    "$rfatool" "$path" "$dst"
  else
    dir="$dst/$(dirname "$file")"
    if [[ ! -d "$dir" ]]; then
      mkdir -p "$dir"
    fi
    cp "$path" "$dst/$file"
  fi
done
