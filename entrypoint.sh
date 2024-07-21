#!/bin/env bash

## CONSTANTS

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DNS_UPDATE_SCRIPT_PATH=$CURRENT_DIR/dns-update/entrypoint.sh
REGISTRY_SCRIPT_PATH=$CURRENT_DIR/registry/entrypoint.sh
KUBERNETES_SCRIPT_PATH=$CURRENT_DIR/kubernetes/entrypoint.sh
REVERSE_PROXY_SCRIPT_PATH=$CURRENT_DIR/reverse-proxy/entrypoint.sh

source $CURRENT_DIR/utils.sh

## FUNCTIONS

usage() {
  echo -e "\nUsage: $0 <command> <options>"
  echo -e "\nCommands:"
  echo "      start    Start the reverse proxy container"
  echo "      stop     Stop the reverse proxy container"
  echo -e "\nOptions:"
  echo "      --expose        Expose the homelab services to the internet"
}

start() {
  if [ -z $1 ]; then
    log "Starting Registry..."
    bash $REGISTRY_SCRIPT_PATH start

    log "Starting kubernetes..."
    bash $KUBERNETES_SCRIPT_PATH start

  elif [[ $1 == "--expose" ]]; then
    log "Starting Registry..."
    bash $REGISTRY_SCRIPT_PATH start --auth
    
    log "Starting DNS update..."
    bash $DNS_UPDATE_SCRIPT_PATH start

    log "Starting kubernetes..."
    bash $KUBERNETES_SCRIPT_PATH start
    
    log "Starting reverse proxy..."
    bash $REVERSE_PROXY_SCRIPT_PATH start

  else
    log ERROR "Invalid option provided: $1"
    usage
  fi
}

stop() {
  log "Stopping DNS update..."
  bash $DNS_UPDATE_SCRIPT_PATH stop

  log "Stopping registry..."
  bash $REGISTRY_SCRIPT_PATH stop

  log "Stopping kubernetes..."
  bash $KUBERNETES_SCRIPT_PATH stop

  log "Stopping reverse proxy..."
  bash $REVERSE_PROXY_SCRIPT_PATH stop
}

## MAIN

case $1 in
  start)
    start $2
    ;;
  stop)
    stop
    ;;
  *)
    usage
    ;;
esac
