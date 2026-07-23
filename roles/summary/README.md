# Summary

This role provides a post-installation summary of the homelab. It detects
which services are installed and prints their access information to the
console and to `/home/<user>/welcome.txt`.

## Output

The summary includes:

- **MetalLB** — IP address pool range
- **Kubernetes (MicroK8s)** — API server endpoint
- **Headlamp** — dashboard URL (if installed)
- **Traefik** — dashboard URL (if installed)
