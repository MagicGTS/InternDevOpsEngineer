#!/bin/bash

if [[ "$(id -u)" = "0" ]]; then
    echo 'true'
else
    echo 'false'
fi
