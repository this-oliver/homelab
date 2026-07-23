# Traefik

This role sets up [Traefik](https://doc.traefik.io/traefik/getting-started/kubernetes/), a modern HTTP reverse proxy and load balancer, for the Kubernetes (k8s) instance.

## Getting Started

Prerequisites:

- [Kubernetes](../k8s-base-microk8s) installed
- [Helm](../k8s-base-helm) installed

## Configuration

| Variable | Required | Default | Description |
|---|---|---|---|
| `traefik_chart_version` | no | `41.0.2` | Helm chart version |
| `traefik_domain` | no | `""` (empty = local) | Domain for TLS (e.g. `homelab.example.com`) |
| `traefik_acme_email` | yes if domain set | — | Let's Encrypt email for ACME |
| `traefik_local_suffix` | no | `local` | TLD for local access (e.g. `local` → `traefik.local`) |

### Local access (default)

Without a domain, Traefik is accessible at `http://traefik.local`. You need a local DNS resolver or hosts entry pointing `traefik.local` to your cluster node.

### Domain access with TLS

Set `traefik_domain` and `traefik_acme_email` in `vars/main.yaml` to enable automatic Let's Encrypt certificates:

```yaml
traefik_domain: homelab.example.com
traefik_acme_email: you@example.com
```

This enables HTTP→HTTPS redirect and ACME certificate resolution.

## Usage

To use Traefik, [read this guide](https://doc.traefik.io/traefik/expose/kubernetes/basic/).
