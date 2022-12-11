#!/bin/bash

set -o pipefail
set +e

src_dir="${1:-}"
dst_dir="${2:-}"
nl=$'\n'
mode="date"
keeps=3
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

do=true
while $do; do
    read -p "Archive with [d]ate in names or [s]eq numbers? [d]: " -n 1 answer
    case "$answer" in
        [dD] | '' )
            echo "${nl}Date mode selected"; do=false; mode='date' ;;
        [sS] )
            echo "${nl}Sequnce mode selected"; do=false; mode='seq' ;;
        *)
            echo "${nl}Do not understand" ;;
    esac
done
args=("$src_dir" "-p" "--acls" "--selinux" "--xattrs")
archive_name="$dst_dir/$(basename $src_dir)"
if [ "$mode" == "seq" ]; then
    do=true
    while $do; do
        read -p "You chose sequence mode, choose amount of recent archives to keep and destroying all the rest: [3]" answer
        case "$answer" in
            [1-9]|[1-9][0-9] )
                echo "${nl}Entered: $answer"; do=false; keeps=$answer ;;
            '' )
                echo "${nl}Default [3] selected"; do=false; keeps=3 ;;
            *)
                echo "${nl}Do not understand" ;;
        esac
    done
    BACKUPS=$(find $dst_dir -maxdepth 1 -type f -name $(basename $src_dir).*.tar.gz | grep -Eo '\.([0-9]+)\.tar\.gz$' | cut -d '.' -f 2 | sort -g)
    echo "Deleting old archives"
    for i in $(cat <<< "${BACKUPS}" | tail -n +$(( $keeps + 1 )));do
        rm -f ${archive_name}.${i}.tar.gz
    done
    echo "Rotating archives"
    for i in $(cat <<< "${BACKUPS}" | head -n +$keeps | sort -g -r);do
        mv ${archive_name}.${i}.tar.gz ${archive_name}.$(( $i +1 )).tar.gz
    done
    tar cfa ${archive_name}.0.tar.gz "${args[@]}"
else
    tar cfa ${archive_name}.$(date +%Y%M%d_%H%S).tar.gz "${args[@]}"
fi
