# Traefik

This role sets up [Traefik](https://doc.traefik.io/traefik/getting-started/kubernetes/), a modern HTTP reverse proxy and load balancer, for the Kubernetes (k8s) instance.

## Getting Started

Prerequisites:

- [Kubernetes](../k8s-base-microk8s) installed
- [Helm](../k8s-base-helm) installed
- [Gateway API](../k8s-extension-gateway) installed
- [Cert Manager](../k8s-extension-cert-manager) installed, required when the homelab is served over HTTPS (the playbook installs it before Traefik)

## Configuration

| Variable | Required | Default | Description |
|---|---|---|---|
| `homelab.admin.username` | yes | from `HOMELAB_ADMIN_USERNAME` | Admin username protecting the dashboard |
| `homelab.admin.password` | yes | from `HOMELAB_ADMIN_PASSWORD` | Admin password protecting the dashboard |
| `homelab.domain.url` | no | `""` (empty = local) | Domain for the dashboard and issued certificate (e.g. `homelab.example.com`) |
| `homelab.domain.https.enabled` | no | `true` | Serve the domain over HTTPS via Let's Encrypt. When false, the domain is served over plain HTTP with a warning |
| `homelab.domain.https.email` | when HTTPS enabled | from `HOMELAB_DOMAIN_HTTPS_EMAIL` | Email registered with Let's Encrypt |

### TLS modes

The TLS configuration is derived from the domain settings:

| `domain.url` | `https.enabled` | `https.email` | Result |
|---|---|---|---|
| ✗ | — | — | Local mode: HTTP only, dashboard restricted to the cluster node's subnet |
| ✓ | ✓ | ✓ | ACME mode: Let's Encrypt certificate terminates TLS on the Gateway's `websecure` listener; plain HTTP is redirected to HTTPS |
| ✓ | ✓ | ✗ | **Fails loudly** before install |
| ✓ | ✗ | — | HTTP only with a warning that traffic is unencrypted |

In ACME mode the role creates a cluster-scoped `ClusterIssuer` named
`letsencrypt` (HTTP-01 challenge through the Traefik Gateway) and a
`Certificate` issuing `domain.url` into the Secret `homelab-domain-tls`
in the `traefik` namespace.

> [!NOTE]
> The `ClusterIssuer` is cluster-scoped so workloads in any namespace can request certificates from it. In multi-tenant clusters this should be revisited together with the Gateway listener `namespacePolicy`.

## Usage

Traffic reaches Traefik via a LoadBalancer listening on a public IP addressed configured via [MetalLB](../k8s-extension-metallb). The loadbalance listens to the target host or `ansible_facts['ansible_default_ipv4']['address']`.

### Bare metal behind a home router

1. Point a DNS A record at your public IP (use DDNS if it changes).
2. Forward TCP 80 and 443 on the router to the MetalLB IP assigned to Traefik:

   ```bash
   kubectl get svc --namespace traefik -o wide
   ```

### Bare metal with a public IP or subnet

Set the target host to the public IP. MetalLB announces it on the LAN with L2 so the cluster receives traffic for it directly — no port forwarding needed. Point the DNS A record straight at the public IP. Alternatively keep a private pool and configure 1:1 NAT on the edge firewall.

### Configuring ingress rules

To configure an ingress rule, read [this guide](https://doc.traefik.io/traefik/reference/routing-configuration/http/routing/rules-and-priority).

Applications are exposed by attaching a Gateway API `HTTPRoute` to the
Gateway named `traefik` in the `traefik` namespace.

### Monitoring ingress activity via dashboad

> [!NOTE]
> The dashboard ingress rule is derived from `homelab.domain.url` in [templates/values.yaml.j2](templates/values.yaml.j2). With a domain set, the dashboard is served at `<domain>/traefik/dashboard`; without one, it is restricted to the cluster node's subnet.

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
