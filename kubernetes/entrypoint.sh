#!/bin/env bash

# This script updates some firmware settings and installs microk8s on a
# raspberry pi.

_MODE=$1

# == CONSTANTS ================================================================

BOOT_FILE=/boot/firmware/cmdline.txt
BOOT_INSERT="cgroup_enable=memory cgroup_memory=1"
ALIAS_MICROK8S="alias micro='microk8s'"
ALIAS_KUBERNETES="alias k8='microk8s kubectl'"
ALIAS_HELM="alias helm='microk8s helm3'"

# == FUNCTIONS ================================================================

function usage {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  setup     - installs microk8s (default) "
  echo "  teardown  - uninstalls microk8s"
  exit 1
}

# adds an alias string to the .bashrc file if it is not already there,
# otherwise does nothing
function add_alias {
  ALIAS=$1

  if ! grep -q "$ALIAS" ~/.bashrc; then
    echo " ==== [MicroK8s Install] Adding '$ALIAS' to ~/.bashrc"
    echo "$ALIAS" >> ~/.bashrc
    source ~/.bashrc
  fi
}

# installs snap if not already installed, otherwise does nothing
function install_snap {
  # install snap if not installed (see https://snapcraft.io/docs/installing-snap-on-ubuntu)
  if [ -z "$(which snap)" ]; then
      echo " ==== [MicroK8s Install] Installing snap"
      sudo apt install snapd -y
  fi
}

# installs microk8s, enables some addons and sets up some aliases
function install_microk8s {
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
  microk8s enable dns helm dashboard

  # add aliases
  add_alias "$ALIAS_MICROK8S"
  add_alias "$ALIAS_KUBERNETES"
  add_alias "$ALIAS_HELM"
}

function uninstall_microk8s {
  # uninstall microk8s
  echo " ==== [MicroK8s Install] Uninstalling microk8s"
  sudo snap remove microk8s

  # remove boot insert from file
  if grep -q "$BOOT_INSERT" $BOOT_FILE; then
      echo " ==== [MicroK8s Install] Removing '$BOOT_INSERT' from $BOOT_FILE"
      sed -i "s/$BOOT_INSERT //" $BOOT_FILE
  fi

  # remove aliases
  echo " ==== [MicroK8s Install] Removing aliases from ~/.bashrc"
  sed -i "/$ALIAS_MICROK8S/d" ~/.bashrc
  sed -i "/$ALIAS_KUBERNETES/d" ~/.bashrc
  sed -i "/$ALIAS_HELM/d" ~/.bashrc
}


function setup {
  # update the system
  echo " ==== [MicroK8s Install] Updating system"
  sudo apt update
  
  install_snap
  install_microk8s
  echo " ==== [MicroK8s Install] Microk8s installed!"
}

function teardown {
  uninstall_microk8s
  echo " ==== [MicroK8s Install] Microk8s uninstalled!"
}

# == SCRIPTS ==================================================================

if [ -z "$_MODE" ]; then
  echo " ==== [MicroK8s Install] Setting up microk8s"
  setup
elif [ "$_MODE" == "teardown" ]; then
  echo " ==== [MicroK8s Install] Tearing down microk8s"
  teardown
else
  usage
  exit 1
fi