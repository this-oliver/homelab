#!/bin/env bash

# == CONSTANTS ================================================================

NGINX_CONF_FILE=$(dirname $0)/nginx.conf

# == FUNCTIONS ================================================================

# returns the designated port (NodePort) for the K8 cluster
get_k8_host_port() {
    port=$1
    k8_ingress_nginx_nodeport=$(microk8s kubectl get services -A -o wide | grep NodePort | grep ingress-nginx)
    echo $k8_ingress_nginx_nodeport | grep -E "$port:[0-9]+" | awk -v port="$port" -F "$port:|/" '{print $2}'
}

# == SCRIPTS ==================================================================

# default values
REGISTRY_PORT=5999
K8_HTTP_PORT=$(get_k8_host_port 80)
K8_HTTPS_PORT=$(get_k8_host_port 443)

# create the nginx config file
echo "events {}

stream {
  upstream registry {
      server localhost:$REGISTRY_PORT;
  }

  upstream kubernetes_http {
      server localhost:$K8_HTTP_PORT;
  }

  upstream kubernetes_https {
      server localhost:$K8_HTTPS_PORT;
  }

  server {
      listen 80;
      server_name _;

      proxy_pass kubernetes_http;
  }

  server {
      listen 443;
      proxy_pass kubernetes_https;
  }
}" > $NGINX_CONF_FILE

# run the nginx container
docker run --rm \
  --name reverse-proxy \
  -p 80:80 -p 443:443 \
  -v $NGINX_CONF_FILE:/etc/nginx/nginx.conf:ro \
  nginx
