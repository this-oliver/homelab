INVENTORY ?= inventory/main.yaml
PLAYBOOKS := playbooks
ANSIBLE_PLAYBOOK := ansible-playbook -i $(INVENTORY)

.PHONY: all base kubernetes networking certificates dashboards reverse-proxy summary uninstall uninstall-%

all:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml

base:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/base.yaml

kubernetes:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/kubernetes.yaml

networking:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/networking.yaml

certificates:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/certificates.yaml

dashboards:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/dashboards.yaml

reverse-proxy:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/reverse-proxy.yaml

summary:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/summary.yaml

uninstall:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/homelab.yaml -e "uninstall=true"

uninstall-%:
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOKS)/$*.yaml -e "uninstall=true"
