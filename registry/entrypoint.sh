#!/bin/env bash

## CONSTANTS

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CERT_DIR=${CURRENT_DIR}/certs
AUTH_DIR=${CURRENT_DIR}/auth
STORAGE_DIR=${CURRENT_DIR}/storage

APPLICATION_NAME=registry

REGISRTY_IMAGE=registry:2
REGISTRY_CONTAINER_NAME=registry
REGISTRY_STORAGE_PATH=/var/lib/registry
REGISRTY_CERT_PATH=/certs
REGISRTY_AUTH_PATH=/auth
REGISRTY_HTTP_PORT=5080
REGISTRY_HTTPS_PORT=5443

HTPASSWD_IMAGE=httpd:2

source $CURRENT_DIR/../utils.sh

## FUNCTIONS

usage () {
  echo -e "\nUsage: $0 <command> [options]"
  
  echo -e "\nCommands:"
  echo "  -> start: Start the registry"
  echo "      --ssl     Start the registry in SSL mode"
  echo "      --auth    Start the registry in Auth mode (with SSL)"
  echo "  -> stop: Stop the registry"
}

set_auth () {
  log "Setting up authentication"
  USERNAME="$(prompt "Username (leave empty for default - admin):")"
  PASSWORD="$(prompt "Password (leave empty for default - admin):" --secret)"

  if [[ -z ${USERNAME} ]]; then
    log "No username provided, using default credentials (admin/admin)"
    
    USERNAME="admin"
    PASSWORD="admin"
  fi

  sudo docker run --rm --entrypoint htpasswd ${HTPASSWD_IMAGE} -Bbn ${USERNAME} ${PASSWORD} > ${AUTH_DIR}/htpasswd
}

init_dirs () {
  mkdir -p ${CERT_DIR}
  mkdir -p ${AUTH_DIR}
  mkdir -p ${STORAGE_DIR}
}

start_registry () {
  MODE=$1
  
  init_dirs

  if [[ -n "$MODE" && "$MODE" != "--ssl" && "$MODE" != "--auth" ]]; then
    echo -e "Unknown option: $MODE"
    usage
  fi

  if [[ "$MODE" == "--ssl" ]]; then
    log "Starting the ${APPLICATION_NAME} in SSL mode"

    sudo docker run --detach --rm \
      -p ${REGISTRY_HTTPS_PORT}:443 \
      -e REGISTRY_HTTP_ADDR="0.0.0.0:443" \
      -e REGISTRY_HTTP_TLS_CERTIFICATE=${REGISRTY_CERT_PATH}/domain.pem \
      -e REGISTRY_HTTP_TLS_KEY=${REGISRTY_CERT_PATH}/domain.key \
      -v ${CERT_DIR}:${REGISRTY_CERT_PATH} \
      -v ${STORAGE_DIR}:${REGISTRY_STORAGE_PATH} \
      --name ${REGISTRY_CONTAINER_NAME} \
      ${REGISRTY_IMAGE}

    log "Registry started on port ${REGISTRY_HTTPS_PORT}"
    
  elif [[ "$MODE" == "--auth" ]]; then
    log "Starting the ${APPLICATION_NAME} in Auth mode"

    set_auth

    sudo docker run --detach --rm \
      -p ${REGISTRY_HTTPS_PORT}:443 \
      -e REGISTRY_AUTH=htpasswd \
      -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
      -e REGISTRY_AUTH_HTPASSWD_PATH=${REGISRTY_AUTH_PATH}/htpasswd \
      -e REGISTRY_HTTP_ADDR="0.0.0.0:443" \
      -e REGISTRY_HTTP_TLS_CERTIFICATE=${REGISRTY_CERT_PATH}/domain.pem \
      -e REGISTRY_HTTP_TLS_KEY=${REGISRTY_CERT_PATH}/domain.key \
      -v ${CERT_DIR}:${REGISRTY_CERT_PATH} \
      -v ${AUTH_DIR}:${REGISRTY_AUTH_PATH} \
      -v ${STORAGE_DIR}:${REGISTRY_STORAGE_PATH} \
      --name ${REGISTRY_CONTAINER_NAME} \
      ${REGISRTY_IMAGE}

    log "Registry started on port ${REGISTRY_HTTPS_PORT}"

  else
    log "Starting the ${APPLICATION_NAME} in normal mode"
    
    sudo docker run --detach --rm \
      -p ${REGISRTY_HTTP_PORT}:5000 \
      -v ${STORAGE_DIR}:${REGISTRY_STORAGE_PATH} \
      --name ${REGISTRY_CONTAINER_NAME} \
      ${REGISRTY_IMAGE}

    log "Registry started on port ${REGISRTY_HTTP_PORT}"
  fi

}

stop_registry () {
  log "Stopping the ${APPLICATION_NAME}"
  sudo docker stop ${REGISTRY_CONTAINER_NAME}
}

## MAIN

case $1 in
  "start")
    start_registry $2
    ;;
  "stop")
    stop_registry
    ;;
  *)
    echo -e "Unknown command: $1"
    usage
    exit 1
    ;;
esac
