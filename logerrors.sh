#!/bin/bash

if [[ "$1" = "" ]]; then
  echo "$0 <logdir>"
  exit 1
fi

cat "$1/"*.log | grep -i -B1 "Unknown object or method" | grep -vi "Unknown object or method" | sort | uniq
