# Kubernetes

All applications hosted on the `homelab` are deployed on a Kubernetes (K8) cluster. The cluster is managed by [MicroK8s](https://microk8s.io/), a lightweight Kubernetes distribution that runs on a single node. MicroK8s is a great choice for homelabs because it is easy to install and manage, and it is resource-efficient.

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

## Design Decisions

### Barebone Nginx Ingress Controller

In order to reach the applications hosted on the cluster, we use Ingress resources to define rules (i.e. which kind of requests can go in and out of the cluster) which are enforced by an Ingress Controller. There are different kinds of controllers available (i.e. the in-built add-on `ingress` in MicroK8s) but they all tend to 'hijack' port 443/80 which can be problematic if you have other services expecting to use those ports.

To address this issue, the homelab uses the [Barebone Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters) which sets up a load balancer on a different port (i.e. 30123) and forwards traffic to the appropriate services. This allows use to run a [reverse proxy](../reverse-proxy/README.md) on the host machine to forward traffic from port 443/80 to the respective services (i.e. K8 cluster loadbalancer, a registry, some other random service).
