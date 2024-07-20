#!/bin/env bash

## CONSTANTS

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

CONFIG_PATH="$CURR_DIR/inadyn.conf"
CACHE_PATH="$CURR_DIR/cache"
INADYN_IMAGE="inadyn:latest"
CRONTAB_FREQUENCY="*/30 * * * *"

source $CURR_DIR/../utils.sh

## FUNCTIONS

usage() {
  echo -e "\nUsage: $0 <command>"
  echo -e "\nCommands:"
  echo "      start    Run inadyn container for dynamic DNS updates"
  echo "      cron     Setup crontab for dynamic DNS updates"
  exit 1
}

init_dirs() {
  mkdir -p $CACHE_PATH
}

start_crontab() {
  log "Setting up crontab for dynamic DNS updates"

  # remove existing crontab entries for this script
  crontab -l | grep -v "$CURR_DIR/entrypoint.sh" | crontab -

  # add new crontab entry
  echo "${CRONTAB_FREQUENCY} $CURR_DIR/entrypoint.sh start" | crontab -

  if [ $? -eq 0 ]; then
    log "Crontab setup successful"
  else
    log "Crontab setup failed"
  fi
}

start_dns_update() {
  log "Starting inadyn container for dynamic DNS updates"

  init_dirs

  docker run --rm --detach \
    -v ${CONFIG_PATH}:/etc/inadyn.conf \
    -v ${CACHE_PATH}:/var/cache/inadyn \
    $INADYN_IMAGE -1 --cache-dir=/var/cache/inadyn > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    log "DNS update successful"
  else
    log "DNS update failed"
  fi
}

## MAIN

check_deps "docker"
check_group "docker"

case $1 in
  start)
    start_dns_update
    ;;
  cron)
    start_crontab
    ;;
  *)
    usage
    ;;
esac
