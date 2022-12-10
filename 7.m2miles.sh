#!/bin/bash
meters="${1:-}"
[ -z "$meters" ] && echo "No input" && exit 1
multipler='0.000621371'
ret=$(echo $meters $multipler | awk '{ printf "%f", $1 * $2 }')
echo "$meters meters is equal to $ret miles"
