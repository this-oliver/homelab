# Ansible

```mermaid
graph TD
  AnsibleNode --> NodeA;
  AnsibleNode --> NodeB;
  AnsibleNode --> NodeC;
```

[Ansible](github.com/ansible/ansible) is an open-source tool that lets you automate, with SSH, the configuration of servers with human-readble YAML files in a Infrastructure as Code (IaC) style.

This Ansible setup is designed to prepare a server(s) for web hosting by installing the following components:

- [ ] `podman` to run containers
- [ ] `dynamic-dns` for dynamic DNS updates
- [ ] `microk8s` for container orchestration
  - [ ] `cert-manager` in the microk8s instance for SSL certificate management
  - [ ] `ingress-nginx` in the microk8s instance for reverse proxying

## Getting Started

Pre-requisites on machine running Ansible (control machine):

- install python3
- install ansible

Pre-requisites on target machine(s):

- install python3
- install openssh-server
- add the Ansible control machine's public SSH key to the target machine's `~/.ssh/authorized_keys` file for passwordless SSH access
