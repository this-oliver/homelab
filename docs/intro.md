# Introduction

This guide takes you from nothing to a running homelab. The [README](../README.md) gives you the 30-second overview and quickstart; this page is the expanded version with configuration references and troubleshooting notes.

## What you end up with

- A MicroK8s Kubernetes cluster on a single Ubuntu host
- Kubectl and Helm installed on the host
- A Traefik ingress gateway with a password-protected dashboard
- A Headlamp web dashboard with Trivy vulnerability scanning
- An HAProxy reverse proxy as the only entry from the internet, locked to loopback ports with iptables

Everything is declared in Ansible, so the same commands install, update and remove the stack in a repeatable order.

## Pre-requisites

You need two machines involved:

| Machine | Requirement |
| --- | --- |
| **Control machine** (where you run Ansible) | Python 3.12+, this repository checked out |
| **Target host** (where homelab runs) | Ubuntu 20.04 LTS, 2 CPU, 2 GB RAM, reachable IP/DNS, an SSH user and key |

Optionally, a public domain pointing at the host lets you serve the dashboards and apps with HTTPS via Let's Encrypt.

## Getting Started

### 1. Install dependencies

Create a Python virtual environment and install the Ansible collection requirements:

```bash
python3 -m venv .venv
source .venv/bin/activate

python3 -m pip install -r requirements.txt
```

Note: on modern Ubuntu, `python3-venv` may be a separate package. Install it with `sudo apt install python3-venv` if the `venv` step fails.

### 2. Configure the inventory

```bash
cp ansible/inventory/main.example.yaml ansible/inventory/main.yaml
```

The inventory defines the `controllers` group — the host(s) that get a Kubernetes cluster. Edit `ansible/inventory/main.yaml`:

```yaml
controllers:
  hosts:
    123.123.123.123: # or `homelab.com`
      ansible_port: 22
      ansible_user: foobar
      ansible_ssh_private_key_file: /path/to/key
```

- The key can be the IP address **or** a URL that resolves to the host.
- `ansible_ssh_private_key_file` is the SSH key on your control machine that can log into the host.

### 3. Configure `ansible/config.yaml`

The list of hosts is inventory; everything else about *what* gets installed lives in `ansible/config.yaml`. It has working defaults, so **you can install without touching it**, but every tweakable lever is exposed there and documented below.

| Key | Required | Default | Description |
| --- | --- | --- | --- |
| `homelab.dir` | no | `"~/homelab"` | Directory on the target host for homelab state (`.kube`, HAProxy config, certs). A leading `~` is resolved against the connecting user's home before any role runs. |
| `homelab.k8s.version` | no | `1.36` | Kubernetes version consumed by the kubectl and k8s_core roles (snap channel). |
| `homelab.admin.username` | **yes** | from env | Admin username for dashboards. Read from `HOMELAB_ADMIN_USERNAME`. |
| `homelab.admin.password` | **yes** | from env | Admin password for dashboards. Read from `HOMELAB_ADMIN_PASSWORD`. |
| `homelab.domain.url` | no | from env | Public domain served by the homelab, e.g. `homelab.example.com`. Without one, dashboards are served on the host IP. |
| `homelab.domain.https.enabled` | no | `true` | Whether to serve the domain over HTTPS (requires a valid `https.email`). |
| `homelab.domain.https.email` | no | from env | Email used by Let's Encrypt for certificate management. Required if HTTPS is enabled and a domain is set. |
| `homelab.security.trivy.enabled` | no | `true` | Install the Trivy operator and surface scan results in the Headlamp dashboard. |
| `uninstall` | no | `false` | Internal. Selects each role's `setup` or `teardown` path. `ansible/homelab_uninstall.yaml` sets it to `true` for you; leave it alone. |

### 4. Configure environmental variables (secrets)

Secrets never live in `ansible/config.yaml` — they are read from the environment so nothing sensitive is committed to version control.

```bash
cp .env.example .env
```

Fill in the values. The `REQUIRED` ones must be set for the playbook to run at all:

| Variable | Required | Purpose |
| --- | --- | --- |
| `HOMELAB_ADMIN_USERNAME` | yes | Admin username for dashboard authentication |
| `HOMELAB_ADMIN_PASSWORD` | yes | Admin password for dashboard authentication |
| `HOMELAB_DOMAIN_URL` | no | URL for accessing the homelab remotely |
| `HOMELAB_DOMAIN_HTTPS_ENABLED` | no | Toggle HTTPS on the domain (`true`/`false`, defaults to `true`) |
| `HOMELAB_DOMAIN_HTTPS_EMAIL` | no | Email for configuring HTTPS certificates |
| `HOMELAB_SECURITY_TRIVY_ENABLED` | no | Toggle the Trivy vulnerability scanner (`true`/`false`, defaults to `true`) |

Apply the variables to your terminal session:

```bash
export $(cat .env | tr '\n' ' ')
```

## Usage

Two playbooks do the work: `ansible/homelab.yaml` provisions the stack and `ansible/homelab_uninstall.yaml` tears it down. Neither one gates its own tasks on a flag, so a run only executes the half you asked for.

### Install

Install (or update) the full stack on the target host:

```bash
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml
```

The install playbook runs its plays in dependency order, so the reverse proxy is never installed before the ingress gateway it protects.

### Install individual layers

The playbook is tagged per layer:

```bash
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags base
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags kubernetes
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags networking
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags monitor
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags reverse_proxy
```

### Uninstall

Uninstall the reverse proxy, the cluster and the cluster tooling:

```bash
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab_uninstall.yaml --tags uninstall
```

Or uninstall a single layer:

```bash
make uninstall-kubernetes   # short for --tags kubernetes
make uninstall-helm         # short for --tags helm
```

The Helm-managed releases are **not** part of the default teardown — removing them is opt-in, one layer at a time:

```bash
make uninstall-monitor      # Headlamp + Trivy releases
make uninstall-networking   # Traefik release
```

The underlying commands are `ansible/homelab_uninstall.yaml` with the layer tag, e.g. `--tags monitor`, `--tags networking`, `--tags helm`.

> [!IMPORTANT]
> Run those two **before** `make uninstall`. Removing a release shells out to `helm ... uninstall` against a running cluster, and the default teardown deletes that cluster.

The `base` role has no teardown — it is the foundation everything else assumes, so it is never removed.

> [!NOTE]
> The two playbooks are independent: `homelab.yaml` installs, `homelab_uninstall.yaml` tears down, and tags pick the layer within each. There is no flag that switches direction — an old script that still passes `-e uninstall=true` to `homelab.yaml` fails immediately and points here.

### After install

Your host now runs MicroK8s. Point `kubectl` at it by exporting the kubeconfig on the host:

```bash
export KUBECONFIG=~/homelab/.kube/config.yaml
```

Dashboards:

- **Traefik** — `http://<host>/traefik/dashboard/` (or `https://<domain>/traefik/`)
- **Headlamp** — `http://<host>/dashboard/` (or `https://<domain>/dashboard/`)

Both are protected by the admin credentials from `ansible/config.yaml`.

Try deploying the bundled example app to confirm the ingress path works end to end:

```bash
kubectl apply -f docs/examples/demo.yaml
```

## Troubleshooting

- **`Missing credentials in vars/main.yaml`** — the `HOMELAB_ADMIN_USERNAME`/`HOMELAB_ADMIN_PASSWORD` env vars are not set, or the `export $(cat .env ...)` did not run in this shell.
- **`Unsupported operating system`** — the playbook only supports Ubuntu. Check the host's distribution and version.
- **HTTPS fail without an email** — setting `homelab.domain.url` with HTTPS enabled requires `HOMELAB_DOMAIN_HTTPS_EMAIL`. Disable HTTPS or provide the email.
- **Changes appear not to apply** — MicroK8s roles skip install when the snap already exists (`has_microk8s`). To re-provision, uninstall that layer first, then install again.
- **`ansible/homelab.yaml` fails with "`uninstall` is not a switch on this playbook"** — expected: you (or an old script) passed `-e uninstall=true`. Teardown is `ansible/homelab_uninstall.yaml --tags uninstall`; drop the flag.

## Next steps

- [docs/architecture.md](architecture.md) — how the layers interoperate
- [CONTRIBUTING.md](../CONTRIBUTING.md) — contributing to the project
- [docs/README.md](README.md) — full documentation index
