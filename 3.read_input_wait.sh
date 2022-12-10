#!/bin/bash
nl=$'\n'
read -p "Enter string: " -t 5 string
[ "$?" -ne "0" ] && echo "${nl}I\`m waiting so long..." && exit 1
echo "$string"
