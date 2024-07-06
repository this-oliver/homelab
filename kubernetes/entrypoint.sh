#!/bin/env bash

# This script updates some firmware settings and installs microk8s on a
# raspberry pi.

# == CONSTANTS ================================================================

BOOT_FILE=/boot/firmware/cmdline.txt
BOOT_INSERT="cgroup_enable=memory cgroup_memory=1"
ALIAS_MICROK8S="alias micro='microk8s'"
ALIAS_KUBERNETES="alias k8='microk8s kubectl'"

# == FUNCTIONS ================================================================

# adds an alias string to the .bashrc file if it is not already there
function add_alias {
  ALIAS=$1

  if ! grep -q "$ALIAS" ~/.bashrc; then
    echo " ==== [MicroK8s Install] Adding '$ALIAS' to ~/.bashrc"
    echo "$ALIAS" >> ~/.bashrc
    source ~/.bashrc
  fi
}

# == SCRIPTS ==================================================================

# update the system
echo " ==== [MicroK8s Install] Updating system"
sudo apt update

# install snap if not installed (see https://snapcraft.io/docs/installing-snap-on-ubuntu)
if [ -z "$(which snap)" ]; then
    echo " ==== [MicroK8s Install] Installing snap"
    sudo apt install snapd -y
fi

# add boot insert to file if not already there
if ! grep -q "$BOOT_INSERT" $BOOT_FILE; then
    echo " ==== [MicroK8s Install] Adding '$BOOT_INSERT' to $BOOT_FILE"
    sed -i "1s/^/$BOOT_INSERT /" $BOOT_FILE
fi

# uninstall old versions of microk8s to avoid conflicts
echo " ==== [MicroK8s Install] Uninstalling old versions of microk8s"
sudo snap remove microk8s

# install microk8s (see https://microk8s.io/docs/install-raspberry-pi#installation)
echo " ==== [MicroK8s Install] Installing microk8s"
sudo apt install linux-modules-extra-raspi -y
sudo snap install microk8s --classic --channel=1.30

# enable some addons
echo " ==== [MicroK8s Install] Enabling microk8s addons"
microk8s enable dns cert-manager helm dashboard

# add aliases
add_alias "$ALIAS_MICROK8S"
add_alias "$ALIAS_KUBERNETES"

echo " ==== [MicroK8s Install] Microk8s installed!"
