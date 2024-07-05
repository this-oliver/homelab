# Homelab

The purpose of this folder is to configure key components that support this machines services.

- dynamic-ip: updates DNS providers (i.e. Cloudflare) with this machines latest ip address
- remote-registry: configures the private registry hosted on this machine

## Getting Started

The infrastructure should be configured in the following order:

1. k8 (kubernetes)
2. nginx (reverse-proxy)
3. dynamic-ip (inadyn)
4. private-registry (distribution)
