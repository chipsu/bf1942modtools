#!/bin/bash
shopt -s nocasematch

usage() {
  echo
  echo "  $(basename $0) [options] <source> <destination> [version=git-revision]"
  echo
  echo "    -c  compress archives (slow)"
  echo "    -s  server build"
  echo "    -t  rfapack executable"
  echo
}

verbose=0
compress=0
server=0
rfatool="$(dirname $0)/rfapack"

while getopts "cst:" OPT; do
  case $OPT in
  c)
    compress=1
    ;;
  s)
    server=1
   ;;
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

src="${1:-source}"
dst="${2:-build/dist}"
version="${3:-}"

[[ $compress != 0 ]] && rfaargs="-Compress"

type "$rfatool" >/dev/null 2>&1 || {
  echo "Error: Could not find RFA binary '$1'" >&2
  usage
  exit 1
}

[[ ! -d "$src" ]] && {
  echo "Source '$src' does not exist" >&2
  exit 1
}

[[ $server != 0 ]] && {
  echo "FIXME SERVER BUILD!" >&2
  exit 1
}

echo
echo "$src => $dst..."
echo "rfatool=$rfatool, compress=$compress, server=$server"
echo

exit
mkdir -p "$dst"

archive=( animations menu objects sound standardmesh texture treemesh bf1942/game )

escape() {
  sed -e 's/\([[\/.*]\|\]\)/\\&/g'
}

packdir() {
  for path in "$1/"*; do
    file="${path#$src}"
    file="${file#*/}"
    file="$(echo "$file" |tr '[A-Z]' '[a-z]')"
    if [[ -f "$path" ]]; then
      mkdir -p "$dst/$(dirname "$file")"
      cp "$path" "$dst/$file"
    elif [[ "$file" = bf1942/levels ]]; then
      packdir "$path"
    elif [[ "$file" = bf1942 ]]; then
      packdir "$path"
    else
      if [[ "$file" != bf1942/levels/* && "${archive[@]%%$file}" = "${archive[@]}" ]]; then
        mkdir -p "$dst/$(dirname "$file")"
        cp -r "$path" "$dst/$file"
      else
        out="$dst/archives/$file.rfa"
        echo "$path => $out"
        mkdir -p "$dst/archives/$(dirname "$file")"
        "$rfatool" "$path" "$file" "$out" $rfaargs
      fi
    fi
  done
}

packdir "$src"

init="$dst/init.con"

if [[ -f "$init" ]]; then
  build="$(echo "$(basename "$dst")" | escape)"
  [[ "$version" = "" ]] && version="$build-git-$(git rev-parse HEAD | head -c6 | escape)"
  sed -i "s/\$build/$build/g;s/\$version/$version/g" "$init"
  [[ "$OS" = "Windows_NT" ]] && attrib -r -a "$init"
fi
