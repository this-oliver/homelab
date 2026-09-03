INVENTORY ?= inventory/main.yaml
PLAYBOOKS := playbooks
ANSIBLE_PLAYBOOK := ansible-playbook -i $(INVENTORY)

.PHONY: all base kubernetes networking uninstall uninstall-%

all:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml

base:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags base

kubernetes:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags kubernetes

networking:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags networking

uninstall:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml -e "uninstall=true"

uninstall-%:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml -e "uninstall=true" --tags $*
