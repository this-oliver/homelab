# Homelab

This repository contains the infrastructure as code for my homelab. The homelab hosts a number of applications that are managed by the following services:

1. [kubernetes](./kubernetes/README.md) - manages the containers running the applications
2. [registry](./registry/README.md) - hosts a private docker registry for the images used by the applications
3. [dns-update](./dns-update/README.md) - updates DNS providers with the homelab's latest ip address
4. [reverse-proxy](./reverse-proxy/README.md) - routes incoming requests to the correct application

## Getting Started

Pre-requisites:

- An understanding of containers and container orchestration
- Docker
- MicroK8s

Out of the box, the home lab works locally - that is to say, it is not exposed to the internet. If you want to reach the applications from the internet, you will need to perform some additional steps.

| Feature                                         | Description                                                                                               |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Reach private registry remotely                 | [Setup SSL](./registry/README.md#adding-ssl)                                                              |
| Pull images from private registry in K8 Cluster | [Setup docker-registry secret in K8 cluster](./kubernetes/README.md#pulling-images-from-private-registry) |
| Issue SSL certificates for applications         | [Setup Cloudflare Origin CA Key](./kubernetes/README.md#getting-started)                                  |
| Update DNS with homelab's latest ip address     | [Setup an `inadyn.conf` file with your Cloudflare credentials](./dns-update/README.md#getting-started)    |

## Usage

> [!Note]
> Many of the scripts in this repository require superuser privileges (sudo) to run, mainly, the docker commands. If you don't want to use sudo, you can add your user to the docker group by running `sudo usermod -aG docker $USER` and then logging out and back in or running `newgrp docker`.

There is a [`entrypoint.sh`](./entrypoint.sh) script that can be used to start all the components of the homelab. The script can be run as follows:

```bash
# start the homelab
bash entrypoint.sh start

# start the homelab and expose it to the internet
bash entrypoint.sh start --expose

# stop the homelab
bash entrypoint.sh stop
```

To install the services individually, you can navigate to the respective directories and follow the instructions in the README.md file.
