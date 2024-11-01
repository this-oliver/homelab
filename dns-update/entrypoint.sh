#!/bin/env bash

## CONSTANTS

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

CONFIG_PATH="$CURR_DIR/inadyn.conf"
CACHE_PATH="$CURR_DIR/cache"
INADYN_IMAGE="inadyn:latest"
CRONTAB_FREQUENCY="*/30 * * * *"
SERVICE_NAME="dns-updater"

source $CURR_DIR/../utils.sh

## FUNCTIONS

usage() {
  echo -e "\nUsage: $0 <command>"
  echo -e "\nCommands:"
  echo "      start    Run inadyn container for dynamic DNS updates"
  echo "      cron     Setup crontab for dynamic DNS updates"
}

check_requirements() {
  log "Checking permissions and dependencies..."
  check_sudo
  check_deps "docker"
  check_group "docker"
}

init_dirs() {
  mkdir -p $CACHE_PATH
}

start_crontab() {
  log "(${SERVICE_NAME}) Setting up crontab"

  # remove existing crontab entries for this script
  crontab -l | grep -v "$CURR_DIR/entrypoint.sh" | crontab -

  # add new crontab entry
  echo "${CRONTAB_FREQUENCY} $CURR_DIR/entrypoint.sh start" | crontab -
}

start_dns_update() {
  log "(${SERVICE_NAME}) Starting inadyn container..."

  init_dirs

  sudo docker run --rm --detach \
    -v ${CONFIG_PATH}:/etc/inadyn.conf \
    -v ${CACHE_PATH}:/var/cache/inadyn \
    $INADYN_IMAGE -1 --cache-dir=/var/cache/inadyn > /dev/null 2>&1

  start_crontab
}

## MAIN

case $1 in
  start)
    check_requirements
    start_dns_update
    log "(${SERVICE_NAME}) Service executed!"
    ;;
  cron)
    check_requirements
    start_crontab
    log "(${SERVICE_NAME}) Service cronjob set!"
    ;;
  *)
    usage
    ;;
esac
