#!/bin/bash

set -o pipefail
set +e
currency="${1:-}"
if [ -z "$currency" ];then
    read -p "Please, enter currency: " currency
fi
[ -z "$currency" ] && echo "Cannot proceed" && exit 1

raw=$(curl http://www.floatrates.com/daily/gbp.json)
base="[^}]+rate\":\s?([0-9]+\.[0-9]+)[^}]+inverseRate\":\s?([0-9]+\.[0-9]+)"
[[ $raw =~ $currency$base ]] || exit 1
rate=${BASH_REMATCH[1]}
inverseRate=${BASH_REMATCH[2]}
echo "Exchange $currency => GBP is $inverseRate"
echo "Exchange GBP => $currency is $rate"
