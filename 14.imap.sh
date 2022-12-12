#!/bin/bash

email="${1:-}"
pass="${2:-}"
[[ -z "$email" || -z "$pass" ]] && echo "email or pass didn't provided" && exit 1
response=$(curl --url "imaps://imap.yandex.ru:993" --user "$email":"$pass" -X 'STATUS Inbox (MESSAGES)' 2>/dev/null)
reg='\* STATUS Inbox \(MESSAGES ([0-9]+)\)'
[[ $response =~ $reg ]] || exit 1
echo "${BASH_REMATCH[1]}"
