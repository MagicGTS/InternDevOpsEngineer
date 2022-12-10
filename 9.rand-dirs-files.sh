#!/bin/bash

set -o pipefail
set +e

walk_through(){
    
    local dst_dir="${1:-}"
    local levels="${2:-1}"
    local size="${3:-1024}"
    local elements="${4:-10}"
    [ -z "$dst_dir" ] && echo "No dst dir provided" && exit 1
    if [ -d "$dst_dir" ]; then
        [ ! -w "$dst_dir" ] && echo "Dst dir not writable" && exit 1
    else
        mkdir -p "$dst_dir"
    fi
    for i in $(seq 1 $elements);do
        local _tmp=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32)
        mkdir -p "$dst_dir/$_tmp"
        if [ "$levels" -gt "1" ];then
            walk_through "$dst_dir/$_tmp" $(( $levels - 1 )) $size $elements
        fi
        _tmp=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32)
        dd if=/dev/urandom of="$dst_dir/$_tmp" bs=1b count=$size
    done
}
walk_through $1 $2 $3 $4
