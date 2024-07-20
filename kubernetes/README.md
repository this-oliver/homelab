# Kubernetes

All applications hosted on the `homelab` are deployed on a Kubernetes cluster. The cluster is managed by [MicroK8s](https://microk8s.io/), a lightweight Kubernetes distribution that runs on a single node. MicroK8s is a great choice for homelabs because it is easy to install and manage, and it is resource-efficient.

## Getting Started

Pre-requisites:

- Ubuntu Operating System

```bash
# script that installs kubernetes
bash entrypoint.sh setup

# script that uninstall kubernetes
bash entrypoint.sh teardown

# open the kubernetes dashboard
microk8s dashboard-proxy
```

## Usage

```bash
# deploy an application to the cluster
microk8s kubectl apply -k /path/to/your/kustomization.yaml
```
