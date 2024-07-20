#!/bin/env bash

# This script is a collection of utility functions that can be used in other scripts

log() {
  MESSAGE=$1
  echo " ==== [HOMELAB] $MESSAGE"
}

check_deps() {
  DEPS=$1

  for DEP in $DEPS; do
    if [ -z "$(which $DEP)" ]; then
      log "Please install $DEP to continue"
      exit 1
    fi
  done
}

check_sudo() {
  if [ "$EUID" -ne 0 ]; then
    log "Please run as a superuser (sudo)"
    exit 1
  fi
}

add_alias() {
  ALIAS=$1

  if ! grep -q "$ALIAS" ~/.bashrc; then
    log "Adding '$ALIAS' to ~/.bashrc"
    echo "$ALIAS" >> ~/.bashrc
    source ~/.bashrc
  fi
}
