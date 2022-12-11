#!/bin/bash

set -o pipefail
set +e

src_dir="${1:-}"
dst_dir="${2:-}"
nl=$'\n'
mode="date"
keeps=3

# Constants
RESET='\033[0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'

DATE=$(date +%Y%M%d_%H%S)
LOG_FILE="out_${DATE}.log"

stdout_print() {
    shopt -s nocasematch
    printf "%b\\n" "${*}" | tee -a $LOG_FILE
}
log() {
    stdout_print "${CYAN} ${MAGENTA}$(date "+%T.%2N ")${RESET}${*}"
}
info() {
    log "${GREEN}INFO ${RESET} ==> ${*}"
}
warn() {
    log "${YELLOW}WARN ${RESET} ==> ${*}"
}
error() {
    log "${RED}ERROR${RESET} ==> ${*}"
}

[[ -z "$src_dir" || -z "$dst_dir" ]] && error "DST or SRC dir didn't provided" && exit 1
src_dir=$(readlink -f $src_dir)
dst_dir=$(readlink -f $dst_dir)
[[ $src_dir == "$dst_dir"* || $dst_dir == "$src_dir"* ]] && error "One of the dir is sub dir of another" && exit 2
mkdir -p $dst_dir 2>/dev/null || error "Could not to create dst" || exit 3
SRC_SIZE=$(du -s $src_dir 2>/dev/null | cut -f 1)
DST_SIZE=$(df --output=avail $dst_dir 2>/dev/null | tail -n 1)
[[ -z "$DST_SIZE" ]] && DST_SIZE=0

if [ $(( $DST_SIZE - $SRC_SIZE )) -le "0" ];then
    do=true
    while $do; do
        warn "Not enought free space, do you want to continue (C\Y) or abort (N\A): "
        read -n 1 answer
        echo "${nl}"
        case "$answer" in
            [cCyY] )
                warn "Processing anyway"; do=false ;;
            [nNaA] )
                info "Breaking"; exit 1 ;;
            *)
                warn "Do not understand" ;;
        esac
    done
fi

do=true
while $do; do
    warn "Archive with [d]ate in names or [s]eq numbers? [d]: "
    read -n 1 answer
        echo "${nl}"
    case "$answer" in
        [dD] | '' )
            info "Date mode selected"; do=false; mode='date' ;;
        [sS] )
            info "Sequnce mode selected"; do=false; mode='seq' ;;
        *)
            warn "Do not understand" ;;
    esac
done
args=("$src_dir" "-p" "--acls" "--selinux" "--xattrs")
archive_name="$dst_dir/$(basename $src_dir)"
if [ "$mode" == "seq" ]; then
    do=true
    while $do; do
        warn "You chose sequence mode, choose amount of recent archives to keep and destroying all the rest: [3]"
        read answer
        case "$answer" in
            [1-9]|[1-9][0-9] )
                info "Entered: $answer"; do=false; keeps=$answer ;;
            '' )
                info "Default [3] selected"; do=false; keeps=3 ;;
            *)
                warn "Do not understand" ;;
        esac
    done
    BACKUPS=$(find $dst_dir -maxdepth 1 -type f -name $(basename $src_dir).*.tar.gz | grep -Eo '\.([0-9]+)\.tar\.gz$' | cut -d '.' -f 2 | sort -g)
    info "Deleting old archives"
    for i in $(cat <<< "${BACKUPS}" | tail -n +$(( $keeps + 1 )));do
        rm -f ${archive_name}.${i}.tar.gz 2>/dev/null || error "Could not to remove ${archive_name}.${i}.tar.gz" || exit 3
    done
    info "Rotating archives"
    for i in $(cat <<< "${BACKUPS}" | head -n +$keeps | sort -g -r);do
        mv ${archive_name}.${i}.tar.gz ${archive_name}.$(( $i +1 )).tar.gz 2>/dev/null || error "Could not to rename ${archive_name}.${i}.tar.gz" || exit 3
    done
    tar cfa ${archive_name}.0.tar.gz "${args[@]}" 2>/dev/null || warn "Something going wrong with ${archive_name}.0.tar.gz" || exit 3
else
    tar cfa ${archive_name}.${DATE}.tar.gz "${args[@]}" 2>/dev/null || warn "Something going wrong with ${archive_name}.${DATE}.tar.gz" || exit 3
fi
