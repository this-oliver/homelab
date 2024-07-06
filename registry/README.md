# Private Registry

This directory configures and managaes [distribution](https://distribution.github.io), a private docker registry.

## Getting Started

Pre-requisites:

- docker + docker-compose
- certs for registry domain

## Usage

At a high level, you'll need to setup:

1. setup registry
2. setup TLS/SSL
3. configure nginx

For a basic setup (see the [docker-compose.yaml](docker-compose.yaml) file), you can run the following commands:

```bash
docker compose up --detach
```

### Setup Reverse-Proxy

> See https://distribution.github.io/distribution/recipes/nginx/

Once the registry is up and running, you'll need to create a reverse-proxy that redirects all the requests to `registry.oliverr.net` to the port designated to the registry (see [docker-compose.yaml](./docker-compose.yaml)). Assuming that nothing has been changed in the previous steps, the majority of the work has been laid out in [registry.oliverr.net.conf](./registry.oliverr.net.conf).

Pre-reqs:

- install nginx

```bash
# copy the nginx file to nginx's available sites
sudo cp registry.oliverr.net.conf /etc/nginx/sites-available/

# link t
sudo ln -s /etc/nginx/sites-available/registry.oliverr.net.conf /etc/nginx/sites-enabled/

# inspect nginx
sudo nginx -t

# if enevrything goes well, reload nginx
sudo systemctl reload nginx
```
