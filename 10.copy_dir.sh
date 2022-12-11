#!/bin/bash

set -o pipefail
set +e

src_dir="${1:-}"
dst_dir="${2:-}"
nl=$'\n'

[[ -z "$src_dir" || -z "$dst_dir" ]] && echo "DST or SRC dir didn't provided" && exit 1
src_dir=$(readlink -f $src_dir)
dst_dir=$(readlink -f $dst_dir)
[[ $src_dir == "$dst_dir"* || $dst_dir == "$src_dir"* ]] && echo "One of the dir is sub dir of another" && exit 2
mkdir -p $dst_dir 2>/dev/null
SRC_SIZE=$(du -s $src_dir 2>/dev/null | cut -f 1)
DST_SIZE=$(df --output=avail $dst_dir 2>/dev/null | tail -n 1)
[[ -z "$DST_SIZE" ]] && DST_SIZE=0

if [ $(( $DST_SIZE - $SRC_SIZE )) -le "0" ];then
    do=true
    while $do; do
        read -p "Not enought free space, do you want to continue (C\Y) or abort (N\A): " -n 1 answer
        case "$answer" in
            [cCyY] )
                echo "${nl}Processing anyway"; do=false ;;
            [nNaA] )
                echo "${nl}Breaking"; exit 1 ;;
            *)
                echo "${nl}Do not understand" ;;
        esac
    done
fi
cp -a $src_dir $dst_dir
