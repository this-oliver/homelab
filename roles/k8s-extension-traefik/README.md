# Traefik

This role sets up [Traefik](https://doc.traefik.io/traefik/getting-started/kubernetes/), a modern HTTP reverse proxy and load balancer, for the Kubernetes (k8s) instance.

## Getting Started

Prerequisites:

- [Kubernetes](../k8s-base-microk8s) installed
- [Helm](../k8s-base-helm) installed
- [Gateway API](../k8s-extension-gateway) installed

## Configuration

| Variable | Required | Default | Description |
|---|---|---|---|
| `traefik_chart_version` | no | `41.0.2` | Helm chart version |
| `traefik_domain` | no | `""` (empty = local) | Domain for TLS (e.g. `homelab.example.com`) |
| `traefik_acme_email` | yes if domain set | — | Let's Encrypt email for ACME |
| `traefik_local_suffix` | no | `local` | TLD for local access (e.g. `local` → `traefik.local`) |

Configuring the `traefik_domain` enables HTTP→HTTPS redirect and ACME certificate resolution.

## Usage

There are two ways to use Traefik in homelab:

1. configure ingress rules
2. monitor ingress activity in the traefik dashboard

### Configuring ingress rules

To configure an ingress rule, read [this guide](https://doc.traefik.io/traefik/reference/routing-configuration/http/routing/rules-and-priority).

### Monitoring ingress activity via dashboad

> [!NOTE]
> To re-configure the way that the dashboard is configured, you will need to change the 'match' rule in [templates/values.yaml.js](templates/values.yaml.js). For tips on how to define the rule, see [this guide](https://doc.traefik.io/traefik/reference/routing-configuration/http/routing/rules-and-priority/#rules).

By default, the homelab sets up Traefik so that you can access the dashboard as long as you are part of the same network as the host that the cluster is running on.

To find the service that is exposing the dashboard, run the following command:

```bash
kubectl get svc --namespace traefik -o wide
```

There should be a service with an external IP and port that you can reach. If no external IP exists, you can always expose a port, temporarily, with port-forwarding:

```bash
kubectl port-forward --address 0.0.0.0 --namespace traefik service/<traefik-service-name> :web
```

The command above should provide you with a port that you can use along with the IP of the host machine to reach the dashboard (`http://<HOST_IP>:<PORT>`).
