#!/bin/env bash

# exit if docker is not installed
if [[ -z $(which docker) ]]; then
    echo "docker is not installed. Please install docker to continue."
    exit 1
fi

echo "Updating DNS records..."

# run the inadyn container
sudo docker run --rm \
  -v $PWD/inadyn.conf:/etc/inadyn.conf \
  -v $PWD/cache:/var/cache/inadyn \
  inadyn:latest -1 --cache-dir=/var/cache/inadyn
