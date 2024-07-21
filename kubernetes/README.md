# Kubernetes

All applications hosted on the `homelab` are deployed on a Kubernetes (K8) cluster. The cluster is managed by [MicroK8s](https://microk8s.io/), a lightweight Kubernetes distribution that runs on a single node. MicroK8s is a great choice for homelabs because it is easy to install and manage, and it is resource-efficient.

## Getting Started

Pre-requisites:

- Ubuntu Operating System
- (Optional) Credentials for [DockerHub](https://hub.docker.com) or a [private registry](../registry/README.md) to pull images from
- (Optional) [Cloudflare Origin CA Key](https://dash.cloudflare.com/profile/api-tokens) for issuing SSL certificates for the cluster (might need a different key if you are using a different DNS provider)

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

The cluster employs a `cert-manager` that is implemented with a Cloudflare certificate issuer to automatically issue SSL certificates for the applications hosted on the cluster. All you need is a domain name hosted with Cloudflare and the Origin CA Key to leverage this feature. The `entrypoint.sh` script prompts you to enter the key which is then stored as a secret on the K8 Cluster.

You can leverage the `cert-manager` to issue SSL certificates for your applications by creating a `Ingress` resource with the following annotations:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-app
  annotations:
    cert-manager.io/issuer: cloudflare-issuer                             # <- name of the issuer to use (don't change)
    cert-manager.io/issuer-kind: OriginIssuer                             # <- kind of issuer to use (don't change)
    cert-manager.io/issuer-group: cert-manager.k8s.cloudflare.com         # <- group of issuer to use (don't change)

spec:
  ingressClassName: nginx
  rules:
    - host: foo.oliverrr.net                                              # <- domain name of the application
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: oliver-frontend                                     # <- name of the service to route to (see service.yaml)
                port:
                  number: 80                                              # <- port of the service to route to (see service.yaml)
  tls:
    - hosts:
        - foo.oliverrr.net                                                # <- domain name of the application
      secretName: foo.oliverrr.net-tls                                    # <- name of the secret to store the SSL certificate (the secret is automatically created by the cert-manager)
```

## Design Decisions

### Barebone Nginx Ingress Controller

In order to reach the applications hosted on the cluster, we use Ingress resources to define rules (i.e. which kind of requests can go in and out of the cluster) which are enforced by an Ingress Controller. There are different kinds of controllers available (i.e. the in-built add-on `ingress` in MicroK8s) but they all tend to 'hijack' port 443/80 which can be problematic if you have other services expecting to use those ports.

To address this issue, the homelab uses the [Barebone Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters) which sets up a load balancer on a different port (i.e. 30123) and forwards traffic to the appropriate services. This allows use to run a [reverse proxy](../reverse-proxy/README.md) on the host machine to forward traffic from port 443/80 to the respective services (i.e. K8 cluster loadbalancer, a registry, some other random service).
