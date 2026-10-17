# Homelab Administrator

> [!NOTE]
> This guide assumes that you have experience with command line tools, python, ansible, linux and kubernetes.

This guide takes you from nothing to a running homelab. The root [README](../../README.md) gives you the 30-second overview and quickstart; this page is the expanded version with configuration references and troubleshooting notes.

## What you end up with

- A kubernetes cluster on a single Ubuntu host powered by `MicroK8s`
- Helper tools installed on the host - `Kubectl` and `Helm`
- A gateway for all your traffic powered by `Traefik`
- A dashboard UI for kubernetes cluster powered by `Headlamp`, `Prometheus`, `OpenCost` and `Trivy`
- A reverse proxy as the only entry from the internet, locked to loopback ports with iptables powered by `HAProxy`
- A generated `~/homelab/README.md` summarising the URLs, versions and topology of what was installed

Everything is declared in Ansible, so the same commands install, update and remove the stack in a consistent manner.

## Getting Started

Pre-requisites:

- **Ansible host** - where you run Ansible
  -  Python 3.12+
- **Target host** - at least 1 host for the homelab to run on
  - Ubuntu 20.04 LTS, 
  - 2 CPU, 
  - 2 GB RAM, 
  - reachable IP/DNS,
  - an SSH user and key

Optionally, a public domain pointing at the host lets you serve the dashboards and apps with HTTPS via Let's Encrypt.

### 1. Install dependencies (*on the **provisioning** host*)

Create a Python virtual environment and install the Ansible collection requirements:

```bash
python3 -m venv .venv
source .venv/bin/activate

python3 -m pip install -r requirements.txt
```

### 2. Configure the inventory (*on the **provisioning** host*)

> [!NOTE]
> The homelab requires at least 1 target host as a **controller** and 0 or more hosts as **workers**.

```bash
cp ansible/inventory/main.example.yaml ansible/inventory/main.yaml
```

The inventory defines the `controller` and `worker` groups — the host(s) that get a Kubernetes cluster. Edit `ansible/inventory/main.yaml`:

```yaml
controller:
  hosts:
    111.111.111.111: # or `homelab.example.com`
      ansible_port: 22
      ansible_user: foobar
      ansible_ssh_private_key_file: /path/to/key
      
# workers:
#   hosts:
#     222.222.222.222: # or `worker1.example.com`
#       ansible_port: 22
#       ansible_user: foobar
#       ansible_ssh_private_key_file: /path/to/key
#     333.333.333.333: # or `worker2.example.com`
#       ansible_port: 22
#       ansible_user: foobar
#       ansible_ssh_private_key_file: /path/to/key
```

- The key can be the IP address **or** a URL that resolves to the host.
- `ansible_ssh_private_key_file` is the SSH key on your provisioning machine that can log into the host.

### 3. Configure `ansible/config.yaml` (*on the **provisioning** host*)

The inventory list defines the hosts at our disposal but [`ansible/config.yaml`](../../ansible/config.yaml) defines *what* gets installed as part of the homelab. 

The config has working defaults, so **you can install the homelab without touching it**, but every tweakable lever is exposed there. You can also tweak the config file via env variables (checkout the [.env.example](../../.env.example)).

### 4. Configure environmental variables (secrets)

Secrets never live in [`ansible/config.yaml`](../../ansible/config.yaml) — they are read from the environment so nothing sensitive is committed to version control.

```bash
cp .env.example .env
```

Tweak the values that you'd like to change and apply the variables to your terminal session:

```bash
export $(cat .env | tr '\n' ' ')
```

You can confirm that the variables are live in your terminal session with:

```bash
env | grep 'HOMELAB'
```

## Usage

Two playbooks do the work: [`ansible/homelab.yaml`](../../ansible/homelab.yaml) provisions the homelab and [`ansible/homelab_uninstall.yaml`](../../ansible/homelab_uninstall.yaml) tears it down.

### Install the Homelab

Install (or update) the full stack on the target host:

```bash
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml
```

Once the play is complete, you should have a Kubernetes instance running on your **controller** and, optionally, **workers**. You can find a summary of the setup in your target hosts by visiting `~/homelab/README.md` - you should be able to gather the dashboard URLs, the versions actually deployed, the cluster's nodes and its ingress routes, and how to reach the kubeconfig.

You can also install specific components of the homelab using tags:

```bash
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags base
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags kubernetes #or 'k8s'
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags gateway
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags dashboard
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --tags reverse_proxy
```

> [!TIP]
> You can find available tags with `ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --list-tags`

#### Accessing the Homelab cluster

##### Locally

Once you setup your homelab cluster, you can play around with it simply by ssh'ing into the **controller host** and using the `kubectl` cli.

```bash
# acces the controller node
ssh foobar@111.111.111.111 -i /path/to/key

# inspect pods across all namespaces
kubectl get pods -A
```

##### Remotely

To access your kubernetes cluster remotely, you need to the following access information from your cluster:

- ip address or hostname
- `maintainer` service account's token

The ip address can be gather from your inventory file. The service account needs to be extracted from within the **controller** node.

```bash
# acces the controller node
ssh foobar@111.111.111.111 -i /path/to/key

# create a short-lived token
kubectl create token maintainer -n homelab

# create a token that lives for 24 hours
# kubectl create token maintainer -n homelab --duration=24h
```

After you have gather the access information, you need to setup your machine so that it can reach the remote homelab cluster:

```bash
# create the cluster
kubectl config set-cluster homelab-cluster --server=https://111.111.111.111 --insecure-skip-tls-verify=true

# create the cluster credentials
kubectl config set-credentials homelab-user --token='<TOKEN>'

# create the cluster context
kubectl config set-context homelab --user=homelab-user --cluster=homelab-cluster

# set the cluster context
kubectl config use-context homelab
```

> [!WARNING]
> When setting the *cluster*, the example above uses `--insecure-skip-tls-verify=true` which is insecure because it exposes you to man-in-the-middle attacks since you never verify the connection between your machine and the homelab host!!! Will investigate a better method for setting the cluster.

Once you have set your `kubectl` context, you can interact with the homelab cluster like it's running directly on your machine.

### Uninstalling the homelab

Uninstall the full stack on the target host:

```bash
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab_uninstall.yaml
```

Similar to the install process, you can also uninstall specific components:

```bash
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab_uninstall.yaml --tags kubernetes #or 'k8s'
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab_uninstall.yaml --tags gateway
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab_uninstall.yaml --tags dashboard
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab_uninstall.yaml --tags reverse_proxy
```

### Provisioning a namespace

> Requires that you have a shell on the homelab host OR you have configured remote access for your machine (see [Accessing Homelab Cluster](#accessing-the-homelab-cluster)).

Once the homelab is up and running, you can start provisioning namespaces for applications.

```bash
kubectl create namespace foobar
```

You can also provision access for a developer:

```bash
# create service account
kubectl create serviceaccount developer -n foobar

# bind the service account with a admin role
kubectl create rolebinding developer-binding --clusterrole==admin --serviceaccount=foobar:developer

# generate a token for the service account
kubectl create token developer -n foobar
```

## Next steps

- [developer](user-developer.md) — Deploy application to the homelab
- [docs/CONTRIBUTING.md](../CONTRIBUTING.md) — contributing to the project
- [docs/README.md](../README.md) — full documentation index
