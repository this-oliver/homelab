# reverse proxy
#!/bin/env bash

# == CONSTANTS ================================================================

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NGINX_CONF_PATH=$CURRENT_DIR/nginx.conf
NGINX_IMAGE=nginx:latest #nginxinc/nginx-unprivileged
NGINX_CONTAINER_NAME=reverse-proxy
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443

LOCALHOST=127.0.0.1

K8_HOST=${LOCALHOST}
K8_HTTPS_PORT=4443

REGISTRY_REMOTE_HOST=registry.oliverr.net
REGISTRY_HOST=${LOCALHOST}
REGISTRY_PORT=5443

source $CURRENT_DIR/../utils.sh

# == FUNCTIONS ================================================================

usage() {
  echo -e "\nUsage: $0 <command> <options>"
  echo -e "\nCommands:"
  echo "      start    Start the reverse proxy container"
  echo "            --log    Immediately follow the logs of the reverse proxy container"
  echo "      stop     Stop the reverse proxy container"
  echo "      restart  Restart the reverse proxy container"
  echo "            --log    Immediately follow the logs of the reverse proxy container"
  echo "      logs     Follow the logs of the reverse proxy container"
  exit 1
}

init_nginx_conf() {
  echo "
  events {
    worker_connections 1024;
  }

  stream {
    upstream services {
        server ${REGISTRY_HOST}:${REGISTRY_PORT};
        server ${K8_HOST}:${K8_HTTPS_PORT};
    }

    server {
        listen 443;
        listen [::]:443;

        proxy_pass services;
        proxy_protocol off;
        proxy_next_upstream on;
    }
  }
  " > $NGINX_CONF_PATH

  # restrict write permissions to owner
  chmod 600 $NGINX_CONF_PATH
}

get_logs() {
  docker logs -f ${NGINX_CONTAINER_NAME}
}

start_nginx() {
  log "Starting reverse proxy container"

  init_nginx_conf

  docker run --rm --detach \
    -v ${NGINX_CONF_PATH}:/etc/nginx/nginx.conf:ro \
    --network host \
    --name ${NGINX_CONTAINER_NAME} \
    ${NGINX_IMAGE}

  if [ $? -eq 0 ]; then
    log "Successfully started reverse proxy container on ports ${NGINX_HTTP_PORT} and ${NGINX_HTTPS_PORT}"

    if [ "$1" == "--log" ]; then
      get_logs
    fi
  else
    log ERROR "Failed to start reverse proxy container"
  fi
}

stop_nginx() {
  docker stop ${NGINX_CONTAINER_NAME}

  if [ $? -eq 0 ]; then
    log "Successfully stopped reverse proxy container"
  else
    log ERROR "Failed to stop reverse proxy container"
  fi
}

get_logs() {
  docker logs -f ${NGINX_CONTAINER_NAME}
}

# == SCRIPTS ==================================================================

check_deps "docker"
check_group "docker"

case $1 in
  start)
    start_nginx $2
    ;;
  stop)
    stop_nginx
    ;;
  restart)
    stop_nginx
    start_nginx $2
    ;;
  logs)
    get_logs
    ;;
  *)
    usage
    ;;
esac
