INVENTORY ?= ansible/inventory/main.yaml
ANSIBLE_PLAYBOOK := ansible-playbook -i $(INVENTORY)
INSTALL_PLAYBOOK := ansible/homelab_install.yaml
UNINSTALL_PLAYBOOK := ansible/homelab_uninstall.yaml

.PHONY: all base kubernetes monitor networking reverse_proxy uninstall uninstall-% worker

all install:
	$(ANSIBLE_PLAYBOOK) $(INSTALL_PLAYBOOK)

base:
	$(ANSIBLE_PLAYBOOK) $(INSTALL_PLAYBOOK) --tags base

kubernetes:
	$(ANSIBLE_PLAYBOOK) $(INSTALL_PLAYBOOK) --tags kubernetes

networking:
	$(ANSIBLE_PLAYBOOK) $(INSTALL_PLAYBOOK) --tags networking

reverse_proxy:
	$(ANSIBLE_PLAYBOOK) $(INSTALL_PLAYBOOK) --tags reverse_proxy

monitor:
	$(ANSIBLE_PLAYBOOK) $(INSTALL_PLAYBOOK) --tags monitor

# Removes the reverse proxy, the cluster and the cluster tooling. The Helm
# releases (Headlamp, Trivy, Traefik) are opt-in: run `make uninstall-monitor`
# and `make uninstall-networking` before this, they need a live cluster.
uninstall:
	$(ANSIBLE_PLAYBOOK) $(UNINSTALL_PLAYBOOK) --tags uninstall

uninstall-%:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml -e "uninstall=true" --tags $*

worker:
	$(ANSIBLE_PLAYBOOK) ansible/homelab.yaml --tags worker
