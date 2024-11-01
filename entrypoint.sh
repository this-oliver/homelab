#!/bin/env bash

## CONSTANTS

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DNS_UPDATE_SCRIPT_PATH="$CURRENT_DIR"/dns-update/entrypoint.sh
REGISTRY_SCRIPT_PATH="$CURRENT_DIR"/registry/entrypoint.sh
KUBERNETES_SCRIPT_PATH="$CURRENT_DIR"/kubernetes/entrypoint.sh
REVERSE_PROXY_SCRIPT_PATH="$CURRENT_DIR"/reverse-proxy/entrypoint.sh

source $CURRENT_DIR/utils.sh

## FUNCTIONS

usage() {
  echo -e "\nUsage: $0 <command> <options>"
  echo -e "\nDescription:"
  echo "      This script is used to start and stop the homelab services (registry, kubernetes, reverse proxy, and DNS update) in the correct order and configuration."
  echo -e "\nCommands:"
  echo "      start    Start up the homelab services"
  echo "      stop     Stop the homelab services"
  echo -e "\nOptions:"
  echo "      --expose        Expose the homelab services to the internet"
  echo "      --no-fail       Setup the next service even if the previous one fails"
}

handle_failure() {
  _MESSAGE=$1
  _NO_FAIL=$2

  log ERROR "$_MESSAGE"

  if [[ "$_NO_FAIL" = true ]]; then
    log WARN "Continuing to the next service..."
  else
    exit 1
  fi
}

start() {
  _EXPOSE=false
  _NO_FAIL=false

  # check if the user wants to expose the services
  if [[ "$@" =~ "--expose" ]]; then
    _EXPOSE=true
  fi

  # check if the user wants to continue even if a service fails
  if [[ "$@" =~ "--no-fail" ]]; then
    _NO_FAIL=true
  fi

  if [[ "$_EXPOSE" = true ]]; then
    log "Starting Registry..."
    bash "$REGISTRY_SCRIPT_PATH" start --auth || handle_failure "Failed to start Registry." "$_NO_FAIL"

    log "Starting kubernetes..."
    bash "$KUBERNETES_SCRIPT_PATH" start || handle_failure "Failed to start kubernetes." "$_NO_FAIL"
    
    log "Starting reverse proxy..."
    bash "$REVERSE_PROXY_SCRIPT_PATH" start || handle_failure "Failed to start reverse proxy." "$_NO_FAIL"

    log "Starting DNS update..."
    bash "$DNS_UPDATE_SCRIPT_PATH" start || handle_failure "Failed to start DNS update." "$_NO_FAIL"

  else
    log "Starting Registry..."
    bash "$REGISTRY_SCRIPT_PATH" start || handle_failure "Failed to start Registry." "$_NO_FAIL"

    log "Starting kubernetes..."
    bash "$KUBERNETES_SCRIPT_PATH" start || handle_failure "Failed to start kubernetes." "$_NO_FAIL"
  fi
}

stop() {
  _NO_FAIL=false

  # check if the user wants to continue even if a service fails
  if [[ "$@" =~ "--no-fail" ]]; then
    _NO_FAIL=true
  fi

  log "Stopping DNS update..."
  bash "$DNS_UPDATE_SCRIPT_PATH" stop || handle_failure "Failed to stop DNS update." "$_NO_FAIL"

  log "Stopping registry..."
  bash "$REGISTRY_SCRIPT_PATH" stop || handle_failure "Failed to stop registry." "$_NO_FAIL"

  log "Stopping kubernetes..."
  bash "$KUBERNETES_SCRIPT_PATH" stop || handle_failure "Failed to stop kubernetes." "$_NO_FAIL"

  log "Stopping reverse proxy..."
  bash "$REVERSE_PROXY_SCRIPT_PATH" stop || handle_failure "Failed to stop reverse proxy." "$_NO_FAIL"
}

## MAIN

case "$1" in
  start)
    start "$@"
    ;;
  stop)
    stop "$@"
    ;;
  *)
    usage
    ;;
esac
