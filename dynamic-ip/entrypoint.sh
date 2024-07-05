#!/bin/env bash

# This script updates the cronjob to run the dynamic-ip script every 30 mins.

# exit if docker is not installed
if [[ -z $(which docker) ]]; then
    echo "docker is not installed. Please install docker to continue."
    exit 1
fi

docker run --rm -v $PWD/inadyn.conf:/etc/inadyn.conf -v $PWD/cache:/var/cache/inadyn inadyn:latest -1 --cache-dir=/var/cache/inadyn > /dev/null 2>&1