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

ORIGIN_CA_ISSUER_VERSION="v0.9.0"
ORIGIN_CA_ISSUER_NAME="prod-issuer"
ORIGIN_CA_ISSUER_SECRET_NAME="cloudflare-ca-key"
ORIGIN_CA_ISSUER_RESOURCES=(
    "crds/cert-manager.k8s.cloudflare.com_clusteroriginissuers.yaml"
    "crds/cert-manager.k8s.cloudflare.com_originissuers.yaml"
    "rbac/role-approver.yaml"
    "rbac/role-binding.yaml"
    "rbac/role.yaml"
    "manifests/0-namespace.yaml"
    "manifests/deployment.yaml"
    "manifests/serviceaccount.yaml"
  )

# == FUNCTIONS ================================================================

function usage {
  echo "Usage: $0 <MODE>"
  echo "  MODE      - setup or teardown (default: setup)"
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

# prompts user for docker credentials and sets up a registry secret in kubernetes
function configure_docker_credentials {
  read -p "Do you want to setup docker credentials? [y/N] `echo $'\n> '`" SETUP_DOCKER_CREDENTIALS

  if [[ $SETUP_DOCKER_CREDENTIALS =~ ^[Yy]$ ]]; then
    read -p "Enter your docker username: `echo $'\n> '`" DOCKER_USERNAME
    read -s -p "Enter your docker password: `echo $'\n> '`" DOCKER_PASSWORD
    
    echo -e "\n==== [MicroK8s Install] Setting up docker credentials for $DOCKER_USERNAME"
    
    microk8s kubectl create secret docker-registry dockerhub \
      --docker-server="https://index.docker.io/v1/" \
      --docker-username="$DOCKER_USERNAME" \
      --docker-password="$DOCKER_PASSWORD"
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

# installs cert-manager with cloudflare's issuer
function install_cert_manager {
  ISSUER_TEMP_YAML=$(mktemp)
  
  # [!NOTE] see https://cert-manager.io/docs/installation/helm/
  if [ -z "$(microk8s helm3 repo list | grep jetstack)" ]; then
    echo " ==== [MicroK8s Install] Installing cert-manager"
    
    microk8s helm3 repo add jetstack https://charts.jetstack.io --force-update
    microk8s helm3 install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.15.1 --set crds.enabled=true
  fi
  
  echo " ==== [MicroK8s Install] Installing cloudflare crds, rbac and manifest"

  # apply each resource
  for RESOURCE in "${ORIGIN_CA_ISSUER_RESOURCES[@]}"; do
    microk8s kubectl apply -f https://raw.githubusercontent.com/cloudflare/origin-ca-issuer/${ORIGIN_CA_ISSUER_VERSION}/deploy/$RESOURCE
  done
  
  echo " ==== [MicroK8s Install] Setting up cloudflare origin ca key and origin issuer"
  read -s -p "Enter your cloudflare origin ca key (see https://dash.cloudflare.com/profile/api-tokens): `echo $'\n> '`" CLOUDFLARE_CA_KEY
  
  # prepare origin issuer yaml
  echo "
  apiVersion: cert-manager.k8s.cloudflare.com/v1
  kind: OriginIssuer
  metadata:
    name: "$ORIGIN_CA_ISSUER_NAME"
    namespace: default
  spec:
    requestType: OriginECC
    auth:
      serviceKeyRef:
        name: "$ORIGIN_CA_ISSUER_SECRET_NAME"
        key: key
  " > $ISSUER_TEMP_YAML

  # remove old secret
  microk8s kubectl delete secret --ignore-not-found -n default "$ORIGIN_CA_ISSUER_SECRET_NAME"

  # [!NOTE] see https://github.com/cloudflare/origin-ca-issuer
  microk8s kubectl create secret generic -n default "$ORIGIN_CA_ISSUER_SECRET_NAME" --from-literal key="$CLOUDFLARE_CA_KEY"
  microk8s kubectl apply -f $ISSUER_TEMP_YAML

  # remove the temporary file
  rm $ISSUER_TEMP_YAML
}

function uninstall_cert_manager {
  echo " ==== [MicroK8s Install] Uninstalling cert-manager"
  microk8s helm3 uninstall cert-manager -n cert-manager

  for RESOURCE in "${ORIGIN_CA_ISSUER_RESOURCES[@]}"; do
    microk8s kubectl delete --ignore-not-found -f https://raw.githubusercontent.com/cloudflare/origin-ca-issuer/${ORIGIN_CA_ISSUER_VERSION}/deploy/$RESOURCE
  done

  microk8s kubectl delete secret --ignore-not-found -n default "$ORIGIN_CA_ISSUER_SECRET_NAME"
  microk8s kubectl delete originissuer --ignore-not-found -n default "$ORIGIN_CA_ISSUER_NAME"
}

# installs an ingress controller that routes traffic to services in the cluster
# depending on the host and path of the request (requires cert-manager for tls)
function install_ingress_controller {
  echo " ==== [MicroK8s Install] Installing ingress controller"

  microk8s helm3 upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace "$INGRESS_CONTROLLER_NAME" --create-namespace
}

function uninstall_ingress_controller {
  echo " ==== [MicroK8s Install] Uninstalling ingress controller"
  microk8s helm3 uninstall ingress-nginx -n "$INGRESS_CONTROLLER_NAME"
}

function setup {
  echo " ==== [MicroK8s Install] Updating system"
  sudo apt update
  
  install_snap
  install_microk8s
  install_cert_manager
  install_ingress_controller
  configure_docker_credentials
  echo " ==== [MicroK8s Install] Microk8s installed!"
}

function teardown {
  uninstall_microk8s
  uninstall_cert_manager
  uninstall_ingress_controller
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