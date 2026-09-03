INVENTORY ?= inventory/main.yaml
PLAYBOOKS := playbooks
ANSIBLE_PLAYBOOK := ansible-playbook -i $(INVENTORY)

.PHONY: all base kubernetes uninstall uninstall-%

all:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml

base:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags base

kubernetes:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags kubernetes

uninstall:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml -e "uninstall=true"

uninstall-%:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml -e "uninstall=true" --tags $*
