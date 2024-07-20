# Homelab

This repository contains the infrastructure as code for my homelab. The homelab hosts a number of applications that are managed by the following components:

1. [kubernetes](./kubernetes/README.md) - orchestrates application deployments
2. [registry](./registry/README.md) - hosts a private docker registry
3. [dynamic-ip](./dynamic-ip/README.md) - updates DNS providers with the homelab's latest ip address
4. [reverse-proxy](./reverse-proxy/README.md) - routes traffic to the appropriate services

## Getting Started

> [!TIP]
> Many of the scripts in this repository require superuser privileges (sudo) to run, mainly, the docker commands. If you don't want to use sudo, you can add your user to the docker group by running `sudo usermod -aG docker $USER` and then logging out and back in or running `newgrp docker`.

Pre-requisites:

- Docker
- MicroK8s

Visit each of the directories (in the order listed above) to setup the homelab infrastructure.

