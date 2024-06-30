#!/bin/env bash

dir=$(dirname $0)
nginx_conf=$dir/nginx.conf

get_host_port() {
    port=$1
    k8_ingress_nginx_nodeport=$(microk8s kubectl get services -A -o wide | grep NodePort | grep ingress-nginx)
    echo $k8_ingress_nginx_nodeport | grep -E "$port:[0-9]+" | awk -v port="$port" -F "$port:|/" '{print $2}'
}

# default values
registry_port=5999
#k8_http_port=8080
#k8_https_port=4443
k8_http_port=$(get_host_port 80)
k8_https_port=$(get_host_port 80)

# create the nginx config file
echo "events {}

stream {
  upstream registry {
      server localhost:$registry_port;
  }

  upstream kubernetes_http {
      server localhost:$k8_http_port;
  }

  upstream kubernetes_https {
      server localhost:$k8_https_port;
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
}" > $nginx_conf

# run the nginx container
docker run \
  --name reverse-proxy --rm \
  -p 80:80 -p 443:443 \
  -v $nginx_conf:/etc/nginx/nginx.conf:ro \
  nginx
