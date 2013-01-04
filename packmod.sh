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

[[ "$2" != "" ]] || {
  usage
  exit 1
}

src="$1"
dst="$2"
version="$3"

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
  # MINGW32 does not have mktemp...
  tmp="$TEMP/_bf1942_server_build_$(date +%s)"
  tmp_dir_remove="$tmp"
  mkdir -p "$tmp"
  echo "Making server build..."
  echo "$src => $tmp..."
  
  # find stuff
  find "$src" -type f \
    -not -iname '*.dds' \
    -not -iname '*.wav' \
    -not -iname '*.tga' \
    -not -iname '*.bik' \
    -not -iname '*.rcm' \
    -not -iname '*.lsb' \
  | while read path; do
    # w32 dont have readlink.. just copy it
    file="${path#$src}"
    file="$tmp/$file"
    dir="$(dirname "$file")"
    [[ ! -d "$dir" ]] && mkdir -p "$dir"
    echo "$path => $file"
    cp "$path" "$file"
  done
  
  # make sure root dirs/.rfa files exist (not sure if needed)
  find "$src" -type d -mindepth 1 -maxdepth 1 | while read path; do
    dir="$tmp/$(basename "$path")"
    [[ ! -d "$dir" ]] && {
      mkdir -p "$dir"
      touch "$dir/empty_dir"
    }
  done
  
  # use tmp dir as src
  src="$tmp"
}

echo
echo "$src => $dst..."
echo "rfatool=$rfatool, compress=$compress, server=$server"
echo

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
        cp -r "$path/." "$dst/$file"
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

if [[ -d "$tmp_dir_remove" ]]; then
  rm -rf "$tmp_dir_remove"
fi