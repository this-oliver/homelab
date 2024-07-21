#!/bin/env bash

## CONSTANTS

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CERT_DIR=${CURRENT_DIR}/certs
AUTH_DIR=${CURRENT_DIR}/auth
STORAGE_DIR=${CURRENT_DIR}/storage

REGISRTY_IMAGE=registry:2
REGISTRY_CONTAINER_NAME=registry
REGISTRY_STORAGE_PATH=/var/lib/registry
REGISRTY_CERT_PATH=/certs
REGISRTY_AUTH_PATH=/auth
REGISRTY_HTTP_PORT=5080
REGISTRY_HTTPS_PORT=5443

REGISTRY_DEFAULT_USERNAME=admin
REGISTRY_DEFAULT_PASSWORD=admin

HTPASSWD_IMAGE=httpd:2

SERVICE_NAME="docker-registry"

source $CURRENT_DIR/../utils.sh

## FUNCTIONS

usage () {
  echo -e "\nUsage: $0 <command> <options>"
  
  echo -e "\nCommands:"
  echo "    start: Start the registry"
  echo "    stop: Stop the registry"
  echo -e "\nOptions:"
  echo "      --ssl     Start the registry in SSL mode"
  echo "      --auth    Start the registry in Auth mode (with SSL)"
}

set_auth () {
  log "(${SERVICE_NAME}) Setting up authentication"
  USERNAME="$(prompt "Username (leave empty for default - ${REGISTRY_DEFAULT_USERNAME}):")"
  PASSWORD="$(prompt "Password (leave empty for default - ${REGISTRY_DEFAULT_PASSWORD}):" --secret)"

  if [[ -z ${USERNAME} ]] && [[ -z ${PASSWORD} ]]; then
    log "(${SERVICE_NAME}) No username provided, using default credentials (${REGISTRY_DEFAULT_USERNAME}/${REGISTRY_DEFAULT_PASSWORD})"
    USERNAME="${REGISTRY_DEFAULT_USERNAME}"
    PASSWORD="admin"
  fi

  if [[ -z ${USERNAME} ]]; then
    USERNAME="${REGISTRY_DEFAULT_USERNAME}"
  fi

  if [[ -z ${PASSWORD} ]]; then
    PASSWORD="admin"
  else
    PASSWORD_CONFIRM="$(prompt "Confirm password:" --secret)"

    if [[ "${PASSWORD}" != "${PASSWORD_CONFIRM}" ]]; then
      log ERROR "Passwords do not match!"
      exit 1
    fi
  fi

  sudo docker run --rm --entrypoint htpasswd ${HTPASSWD_IMAGE} -Bbn ${USERNAME} ${PASSWORD} > ${AUTH_DIR}/htpasswd
}

is_registry_running () {
  if [ -n "$(sudo docker ps -q -f name=${REGISTRY_CONTAINER_NAME})" ]; then
    echo "true"
  else
    echo "false"
  fi
}

init_dirs () {
  mkdir -p ${CERT_DIR}
  mkdir -p ${AUTH_DIR}
  mkdir -p ${STORAGE_DIR}
}

stop_registry () {
  log "(${SERVICE_NAME}) Stopping the container..."
  sudo docker stop ${REGISTRY_CONTAINER_NAME}
}

start_registry () {
  MODE=$1
  
  init_dirs

  if [[ -n "$MODE" && "$MODE" != "--ssl" && "$MODE" != "--auth" ]]; then
    echo -e "Unknown option: $MODE"
    usage
  fi

  if [[ "$(is_registry_running)" == "true" ]]; then
    log WARN "(${SERVICE_NAME}) Stopping the current container..."
    stop_registry
  fi

  if [[ "$MODE" == "--ssl" ]]; then
    log "(${SERVICE_NAME}) Starting container in SSL mode..."

    sudo docker run --detach --rm \
      -p ${REGISTRY_HTTPS_PORT}:443 \
      -e REGISTRY_HTTP_ADDR="0.0.0.0:443" \
      -e REGISTRY_HTTP_TLS_CERTIFICATE=${REGISRTY_CERT_PATH}/domain.pem \
      -e REGISTRY_HTTP_TLS_KEY=${REGISRTY_CERT_PATH}/domain.key \
      -v ${CERT_DIR}:${REGISRTY_CERT_PATH} \
      -v ${STORAGE_DIR}:${REGISTRY_STORAGE_PATH} \
      --name ${REGISTRY_CONTAINER_NAME} \
      ${REGISRTY_IMAGE}
    
  elif [[ "$MODE" == "--auth" ]]; then
    log "(${SERVICE_NAME}) Starting container in Auth mode..."

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

  else
    log "(${SERVICE_NAME}) Starting container ..."
    
    sudo docker run --detach --rm \
      -p ${REGISRTY_HTTP_PORT}:5000 \
      -v ${STORAGE_DIR}:${REGISTRY_STORAGE_PATH} \
      --name ${REGISTRY_CONTAINER_NAME} \
      ${REGISRTY_IMAGE}
  fi

}

## MAIN

case $1 in
  start)
    start_registry $2
    
    if [[ "$2" == "--ssl" ]] || [[ "$2" == "--auth" ]]; then
      log "(${SERVICE_NAME}) Service started in SSL mode on port ${REGISTRY_HTTPS_PORT}!"
    else
      log "(${SERVICE_NAME}) Service started on port ${REGISRTY_HTTP_PORT}!"
    fi
    ;;
  stop)
    stop_registry
    log "(${SERVICE_NAME}) Service stopped!"
    ;;
  *)
    echo -e "Unknown command: $1"
    usage
    exit 1
    ;;
esac
