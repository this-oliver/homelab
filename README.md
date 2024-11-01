# Homelab

This repository contains a number of scripts that setup different computing services:

1. [kubernetes](./kubernetes/README.md) - manages the containers running the applications
2. [registry](./registry/README.md) - hosts a private docker registry for the images used by the applications
3. [dns-update](./dns-update/README.md) - updates DNS providers with the homelab's latest ip address
4. [reverse-proxy](./reverse-proxy/README.md) - routes incoming requests to the correct application

When combined and hooked to the internet, the services above form a private cloud infrastructure that can host a number of diverse applications. Out of the box, the home lab works locally - that is to say, it is not exposed to the internet.

## Getting Started

> [!Note]
> Several services/scripts in this repository require superuser privileges (`sudo`) to run install dependencies (kubernets service) ro to run docker commands (i.e. dns-update, reverse-proxy and registry). Please ensure you have the necessary permissions before running the scripts.

Pre-requisites:

- An understanding of containers and container orchestration
- Docker
- MicroK8s

| Feature                                         | Description                                                                                               |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Reach private registry remotely                 | [Setup SSL](./registry/README.md#adding-ssl)                                                              |
| Pull images from private registry in K8 Cluster | [Setup docker-registry secret in K8 cluster](./kubernetes/README.md#pulling-images-from-private-registry) |
| Issue SSL certificates for applications         | [Setup Cloudflare Origin CA Key](./kubernetes/README.md#getting-started)                                  |
| Update DNS with homelab's latest ip address     | [Setup an `inadyn.conf` file with your Cloudflare credentials](./dns-update/README.md#getting-started)    |

## Usage

> [!Note]
> Out of the box, the homelab is designed to work locally, on your machine and private network. To expose the services to the internet, you'll need to setup a reverse proxy and update your DNS provider with the homelab's latest ip address (see [dns-update](./dns-update/README.md) for more information).

To simplify the process of starting the homelab, the repository contains an entrypoint script that can be used to start all the services at once.

```bash
# start the homelab
bash entrypoint.sh start

# start the homelab and expose it to the internet
bash entrypoint.sh start --expose

# stop the homelab
bash entrypoint.sh stop
```

To install the services individually, you can navigate to the respective directories and follow the instructions in the README.md file.

```bash
# install the kubernetes service
bash kubernetes/entrypoint.sh start

# install the registry service
bash registry/entrypoint.sh start
```

## Contributing

If you'd like to contribute to this repository, please fork the repository and submit a pull request. For major changes, please open an issue first to discuss what you would like to change.
