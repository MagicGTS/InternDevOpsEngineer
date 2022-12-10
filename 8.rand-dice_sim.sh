#!/bin/bash
sim_num="${1:-700}"
declare -a ret=( "0" "0" "0" "0" "0" "0" )
declare -a names=( "единиц" "двоек" "троек" "четверок" "пятерок" "шестерок" )
for i in $(seq 1 $sim_num);do
    num=$(( $RANDOM % 6 + 1 ))
    ret[ $(( $num - 1 )) ]=$(( ${ret[$(( $num - 1 ))]} + 1 ))
done
for i in "${!names[@]}";do
    echo "${names[$i]} = ${ret[$i]}"
done | column -t