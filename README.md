# Homelab

## Getting Started

Pre-requisites:

- Python 3.12+ installed
- Linux machine (Ubuntu 20.04 LTS)
  - 2cpu minimum
  - 2gb ram minimum
  - ip address

### Install dependencies

```bash
# setup python env
python3 -m venv .venv
source .venv/bin/activate

# install deps
python3 -m pip install -r requirements.txt
```

### Configure `inventory/main.yaml`

First, create the `inventory/main.yaml` file from the example file `inventory/main.example.yaml`:

```bash
cp inventory/main.example.yaml inventory/main.yaml
```

Configure the `inventory/main.yaml` such that an ip address or url is provided for the controller host. Make sure to also configure the port, user and private key path for the host.

### Configure `config.yaml`

The `config.yaml` is used to configure the homelab. The homelab should be able to install without edditing this file however if there is anything that you, as a user, can tweak then it should be found here.

### Configure environmental variables (secrets)

First, create a .env file based on the `.env.example` template.

```bash
cp .env.example .env
```

Second, fill in the REQUIRED values. The values are explained below:

- HOMELAB_ADMIN_USERNAME (REQUIRED) - admin username
- HOMELAB_ADMIN_PASSWORD (REQUIRED) - admin password for authenticating
- HOMELAB_DOMAIN_URL (OPTIONAL) - url for accessing homelab remotely
- HOMELAB_DOMAIN_HTTPS_EMAIL (OPTIONAL) - email for configuring HTTPS certificates

Lastly, apply the env variables to the terminal's session:

```bash
export $(cat .env | tr '\n' ' ')
```

## Usage

Install homelab on target host:

```bash
ansible-playbook -i inventory/main.yaml playbooks/homelab.yaml
```

Uninstall homelab on target host:

```bash
ansible-playbook -i inventory/main.yaml playbooks/homelab.yaml -e uninstall=true
```
