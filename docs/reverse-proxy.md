# Reverse Proxy

A reverse proxy sits between clients and backend services, forwarding requests to the appropriate destination and returning the response. Unlike a forward proxy (which sits in front of clients), a reverse proxy sits in front of servers.

## Why You Need One

The homelab runs multiple services — Kubernetes apps, a dashboard, potentially a private registry — that all need to share the same ports (80 for HTTP, 443 for HTTPS). A reverse proxy inspects incoming requests and routes them to the correct service based on the hostname or path.

```mermaid
graph LR
    Client["Client"] --> Proxy["Reverse Proxy<br/>:80 / :443"]
    Proxy --> AppA["App A<br/>(app.example.com)"]
    Proxy --> AppB["App B<br/>(api.example.com)"]
    Proxy --> Dashboard["Dashboard<br/>(k8s.example.com)"]
```

Without a reverse proxy, each service would need its own port, and clients would have to remember port numbers alongside hostnames.

## Why Traefik

There are many reverse proxies (nginx, Caddy, HAProxy). The homelab uses [Traefik](https://traefik.io) because it:

- **integrates natively with Kubernetes** — discovers services automatically via the Kubernetes API
- **supports automatic TLS** — integrates with Let's Encrypt via Cert Manager
- **avoids port conflicts** — the default Kubernetes ingress controller "hijacks" ports 80/443 on the host, which can conflict with other services. Traefik can be configured to listen on different ports or run as a `LoadBalancer` service via MetalLB, sidestepping this problem entirely

## How It Works in the Homelab

When a client sends a request (e.g. `https://app.example.com`):

```mermaid
sequenceDiagram
    participant C as Client
    participant T as Traefik
    participant K as Kubernetes

    C->>T: HTTPS request to app.example.com
    T->>T: match route (host header)
    T->>K: forward to matching service
    K->>T: response from pod
    T->>C: return response to client
```

1. Traefik receives the request on port 443.
2. It matches the `Host` header against its routing rules.
3. It forwards the request to the correct Kubernetes service.
4. The response travels back through Traefik to the client.

## Two Modes

### Local access (default)

Without a domain, the Traefik dashboard is only reachable from clients on the same subnet as the cluster node (the ingress route is restricted with a `ClientIP` rule). Reach it via the Traefik service's external IP and port:

```bash
kubectl get svc --namespace traefik -o wide
```

### Domain access with TLS

Set `homelab.domain.name` (and `homelab.domain.https.email` for TLS certificate management) in `vars/main.yaml`:

```yaml
homelab:
  domain:
    name: homelab.example.com
    https:
      enabled: true
      email: you@example.com
```

This enables:
- Traefik dashboard at `https://homelab.example.com/traefik/dashboard`
- Automatic TLS certificate issuance via Let's Encrypt
- HTTP → HTTPS redirect
- HTTPS access at your domain (e.g. `https://app.homelab.example.com`)

## Learn More

- [Traefik Kubernetes documentation](https://doc.traefik.io/traefik/getting-started/kubernetes/)
- [Traefik routing concepts](https://doc.traefik.io/traefik/routing/services/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
