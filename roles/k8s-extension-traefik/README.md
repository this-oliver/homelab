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
| `homelab.admin.username` | yes | from `HOMELAB_ADMIN_USERNAME` | Admin username protecting the dashboard |
| `homelab.admin.password` | yes | from `HOMELAB_ADMIN_PASSWORD` | Admin password protecting the dashboard |
| `homelab.domain.name` | no | `""` (empty = local) | Domain for the dashboard (e.g. `homelab.example.com`) |

The dashboard ingress rule is derived from `homelab.domain.name`:

- when set, the dashboard is served at `https://<domain>/traefik/dashboard`
- when empty, it is restricted to clients on the same subnet as the cluster node (`ClientIP` rule)

## Usage

There are two ways to use Traefik in homelab:

1. configure ingress rules
2. monitor ingress activity in the traefik dashboard

### Configuring ingress rules

To configure an ingress rule, read [this guide](https://doc.traefik.io/traefik/reference/routing-configuration/http/routing/rules-and-priority).

### Monitoring ingress activity via dashboad

> [!NOTE]
> The dashboard ingress rule is derived from `homelab.domain.name` in [templates/values.yaml.j2](templates/values.yaml.j2). With a domain set, the dashboard is served at `<domain>/traefik/dashboard`; without one, it is restricted to the cluster node's subnet.

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
