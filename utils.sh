#!/bin/env bash

# This script is a collection of utility functions that can be used in other scripts

log() {
  MESSAGE=$1
  PREFIX="==== [HOMELAB]"
  
  # log messages with different colors based on the message type - green for standard
  # messages, red for errors, and yellow for warnings
  
  if [[ $MESSAGE == "ERROR"* ]]; then
    echo -e "\033[0;31m$PREFIX (ERROR) $2\033[0m"
  elif [[ $MESSAGE == "WARN"* ]]; then
    echo -e "\033[0;33m$PREFIX (WARNING) $2\033[0m"
  else
    echo -e "\033[0;32m$PREFIX $MESSAGE\033[0m"
  fi
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

check_group() {
  if [ -z "$(groups | grep $1)" ]; then
    log "Please add your user to the $1 group (sudo usermod -aG docker $USER) or run as a superuser (sudo bash $0)"
    exit 1
  fi
}

add_alias() {
  ALIAS=$1

  if [ -z "$(alias | grep k8)" ]; then
    log "Adding \"$ALIAS\" to ~/.bashrc"
    echo "$ALIAS" >> ~/.bashrc
    source ~/.bashrc
  fi
}

remove_alias() {
  ALIAS=$1

  if ! [ -z "$(alias | grep k8)" ]; then
    log "Removing '$ALIAS' from ~/.bashrc"
    sed -i "/$ALIAS/d" ~/.bashrc
    source ~/.bashrc
  fi
}
