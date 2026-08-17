INVENTORY ?= inventory/main.yaml
PLAYBOOKS := playbooks
ANSIBLE_PLAYBOOK := ansible-playbook -i $(INVENTORY)

.PHONY: all base kubernetes networking certificates dashboards reverse-proxy summary uninstall uninstall-%

all:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml

base:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags base

kubernetes:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags kubernetes

networking:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags networking

certificates:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags certificates

dashboards:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags dashboards

reverse-proxy:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags reverse-proxy

summary:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml --tags summary

uninstall:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml -e "uninstall=true"

uninstall-%:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml -e "uninstall=true" --tags $*
