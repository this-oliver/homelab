# Role: k8s_extension_traefik

## What

Installs the Traefik ingress gateway into the cluster as a Helm release (`traefik/traefik` chart), exposes it through NodePorts `30080`/`30443`, and ships a password-protected dashboard with rate limiting, HTTP→HTTPS redirect and optional Let's Encrypt certificates.

## Why

Traefik is the single routing entry point *inside* the cluster: it terminates traffic for the Headlamp dashboard, demo apps and future workloads via `IngressRoute` resources. Centralizing routing here gives every app a consistent path with auth, rate limits and TLS baked in.

## How (install)

```mermaid
flowchart LR
    pre[preflight checks] --> assert{domain set + HTTPS?}
    assert -- yes + no email --> fail[assert fails<br/>email required]
    assert --> install[include tasks/helm.yaml<br/>install traefik release]
    install --> objects[render values.yaml.j2]
    objects --> sidecars[extraObjects: dashboard auth secret,<br/>middlewares (auth, redirect, rate-limit, https-redirect)]
    sidecars --> done((done))
```

The `values.yaml.j2` template does most of the work:

- **`https_enabled`** — gated on `homelab.domain.url`, `homelab.domain.https.enabled` and a valid ACME email. When enabled, Traefik creates a `defaultCertResolver` (Let's Encrypt) and the dashboard + ingress use the `websecure` entry point.
- **Dashboard** — always enabled, served at `<domain>/traefik` or the host IP `/traefik` when no domain is set. Guarded by a Kubernetes basic-auth Secret rendered from `homelab.admin.*` plus the `rate-limit` middleware.
- **PROXY protocol** — `web`/`websecure` listen on NodePorts `30080`/`30443` with proxy protocol enabled, so the HAProxy reverse proxy can forward client IPs (see [reverse_proxy](../reverse_proxy/README.md)).
- **RBAC** — Traefik gets a dedicated service account and cluster role.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `helm_release.name` | `traefik` | Helm release name. |
| `helm_release.namespace` | `traefik` | Deployed namespace. |
| `helm_release.chart.ref` / `.version` | `traefik/traefik` / `41.0.2` | Chart and version. |
| `helm_release.repo` | `traefik` @ `https://traefik.github.io/charts` | Helm repository. |
| ports | `web` → NodePort `30080`, `websecure` → NodePort `30443` | NodePorts consumed by the reverse proxy. |
| `homelab.admin.*` | from env | Dashboard basic-auth credentials. |
| `homelab.domain.*` | from env | Domain, HTTPS toggle and ACME email. |

See [tasks/helm.yaml](../../tasks/helm.yaml) for the shared `helm_release` contract.

## Dependencies

- `tasks/preflight.yaml` — shared preflight checks.
- `tasks/helm.yaml` — shared Helm repo + release management.
- A running cluster (`k8s_core`) and the `kubernetes` tooling.

## Tags

- `networking`
- `traefik`

```bash
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags networking
```

## Uninstall

Uninstalls the `traefik` Helm release (and its namespace artifacts) via the shared `tasks/helm.yaml`. Opt-in, not part of the default teardown: it is tagged `networking` without the `uninstall` tag, so run `--tags networking` (or `make uninstall-networking`) before the default teardown — `helm ... uninstall` needs the cluster that `k8s_core` removes, and the reverse proxy depends on these NodePorts.
