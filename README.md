# Homelab

This repository sets up a lightweight and self-hosted infrastructure for my homelab where I deploy a number of applications and projects. The homelab includes a variety of services, such as:

1. [container orchestration with `microk8s`](/docs/container-orchestration.md) - orchestrates application deployments
2. [dynamic dns updates with `dynamic-dns`](/docs/dynamic-dns-update.md) - updates DNS providers with the homelab's latest ip address

## Getting Started

Prerequisites:

1. Python
2. Setup `./ansible/inventory.yaml` (see `./ansible/inventory.exampl.yaml`)

## Usage

To install a homelab, run:

```bash
ansible-playbook -i ansible/inventory.yaml ansible/playbooks/homelab.yaml
```

- `-i <PATH>`: ansible inventory path

To install with a loadbalancer, run:

```bash
ansible-playbook -i ansible/inventory.yaml -e metallb_ip_pool=123.123.123.180-123.123.123.190 ansible/playbooks/homelab.yaml
```

- `-e <VAR>`: ansible variables

To uninstall, run:

```bash
ansible-playbook -i ansible/inventory.yaml ansible/playbooks/homelab.yaml -e "uninstall=true"
```
