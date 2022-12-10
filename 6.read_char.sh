#!/bin/bash
nl=$'\n'
read -p "Enter char: " -n 1 char
echo "$nl$char"
case "$char" in
    [A-Z] )
        echo "Upper case letter" ;;
    [a-z] )
        echo "Lower case letter" ;;
    [0-9] )
        echo "Digits" ;;
    [\-\'\"\;.,!?] )
        echo "Punctuations" ;;
    [\ ] )
        echo "Space" ;;
    *)
        echo "Other" ;;
esac
