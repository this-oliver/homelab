INVENTORY ?= inventory/main.yaml
PLAYBOOKS := playbooks
ANSIBLE_PLAYBOOK := ansible-playbook -i $(INVENTORY)

.PHONY: all base kubernetes networking reverse-proxy monitor uninstall uninstall-%

all:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml

base:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags base

kubernetes:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags kubernetes

networking:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags networking

reverse-proxy:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags reverse-proxy

monitor:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags monitor

uninstall:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml -e "uninstall=true"

uninstall-%:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml -e "uninstall=true" --tags $*
