INVENTORY ?= ansible/inventory/main.yaml
ANSIBLE_PLAYBOOK := ansible-playbook -i $(INVENTORY)

.PHONY: all base kubernetes monitor networking reverse_proxy uninstall uninstall-% worker

all:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml

base:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml --tags base

kubernetes:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml --tags kubernetes

networking:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml --tags networking

reverse_proxy:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml --tags reverse_proxy

monitor:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml --tags monitor

uninstall:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml -e "uninstall=true"

uninstall-%:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml -e "uninstall=true" --tags $*

worker:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml --tags worker
