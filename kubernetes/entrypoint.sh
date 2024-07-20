#!/bin/env bash

# This script updates some firmware settings and installs microk8s on a
# raspberry pi.

# == CONSTANTS ================================================================

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ALIAS_HELM="alias helm='microk8s helm3'"
ALIAS_KUBERNETES="alias k8='microk8s kubectl'"
ALIAS_MICROK8S="alias micro='microk8s'"
BOOT_FILE_PATH=/boot/firmware/cmdline.txt
BOOT_INSERT="cgroup_enable=memory cgroup_memory=1"
DOCKER_REGISTRY_SECRET_NAME="dockerhub"
DOCKER_DEFAULT_REGISTRY="https://index.docker.io/v1/"
CERT_MANAGER_NAME="cert-manager"
INGRESS_CONTROLLER_NAME="ingress-nginx"
INGRESS_CONTROLLER_RESOURCE="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/baremetal/deploy.yaml"
MICROK8S_ADDONS=(
  "dns"
  "helm"
  "dashboard"
)
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
ORIGIN_CA_ISSUER_VERSION="v0.9.0"

source $CURRENT_DIR/../utils.sh

# == FUNCTIONS ================================================================

usage() {
  echo -e "\nUsage: $0 <command>"
  echo -e "\nCommands:"
  echo "  start <options>     - setup k8 stack"
  echo "  stop <options>      - remove k8 stack"
  echo -e "\nOptions:"
  echo "  --k8                - only setup/remove microk8s"
  echo "  --cert              - only setup/remove cert-manager"
  echo "  --ingress           - only setup/remove ingress controller"
}

# installs snap if not already installed
install_snap() {
  # install snap if not installed (see https://snapcraft.io/docs/installing-snap-on-ubuntu)
  if [ -z "$(which snap)" ]; then
      log "[Kubernetes] Installing snap..."
      apt install -y snapd
      log "[Kubernetes] Successfully installed snap"
  fi
}

# installs microk8s, adds boot insert, enables some addons and sets up some aliases
install_microk8s() {
  if ! grep -q "$BOOT_INSERT" $BOOT_FILE_PATH; then
      log "[Kubernetes] Adding '$BOOT_INSERT' to $BOOT_FILE_PATH (requires reboot)..."
      sed -i "1s/^/$BOOT_INSERT /" $BOOT_FILE_PATH
  fi

  if [ -z "$(which microk8s)" ]; then
    # uninstall old versions of microk8s to avoid conflicts
    log "[Kubernetes] Uninstalling old versions of microk8s..."
    snap remove microk8s

    # install microk8s (see https://microk8s.io/docs/install-raspberry-pi#installation)
    log "[Kubernetes] Installing microk8s..."
    apt install -y linux-modules-extra-raspi
    snap install microk8s --classic --channel=1.30
  else
    log "[Kubernetes] microk8s already installed. Updating instead..."
    snap refresh microk8s --classic --channel=1.30
  fi

  # enable some addons
  log "[Kubernetes] Enabling microk8s addons ${MICROK8S_ADDONS[@]}..."
  for add_on in "${MICROK8S_ADDONS[@]}"; do
    microk8s enable $add_on
  done

  # add aliases
  log "[Kubernetes] Adding aliases..."
  add_alias "$ALIAS_MICROK8S"
  add_alias "$ALIAS_KUBERNETES"
  add_alias "$ALIAS_HELM"
}

uninstall_microk8s() {
  log "[Kubernetes] Uninstalling microk8s..."
  snap remove microk8s

  if grep -q "$BOOT_INSERT" $BOOT_FILE_PATH; then
      log "[Kubernetes] Removing '$BOOT_INSERT' from $BOOT_FILE_PATH"
      sed -i "s/$BOOT_INSERT //" $BOOT_FILE_PATH
  fi

  log "[Kubernetes] Removing aliases..."
  remove_alias "$ALIAS_MICROK8S"
  remove_alias "$ALIAS_KUBERNETES"
  remove_alias "$ALIAS_HELM"
}

# installs cert-manager + cloudflare's issuer for issuing certificates to
# applications deployed on the cluster via the cloudflare api
install_cert_manager() {
  log "[Kubernetes] Installing cert-manager..."
  ISSUER_TEMP_YAML=$(mktemp)
  
  # [!NOTE] see https://cert-manager.io/docs/installation/helm/
  if [ -z "$(microk8s helm3 repo list | grep jetstack)" ]; then
    log "[Kubernetes] Installing cert-manager..."

    microk8s helm3 repo add jetstack https://charts.jetstack.io --force-update
    microk8s helm3 install cert-manager jetstack/cert-manager --namespace "$CERT_MANAGER_NAME" --create-namespace --version v1.15.1 --set crds.enabled=true
  fi

  # apply each resource
  log "[Kubernetes] Installing cloudflare origin ca issuer..."
  for RESOURCE in "${ORIGIN_CA_ISSUER_RESOURCES[@]}"; do
    microk8s kubectl apply -f https://raw.githubusercontent.com/cloudflare/origin-ca-issuer/${ORIGIN_CA_ISSUER_VERSION}/deploy/$RESOURCE
  done
  
  log "[Kubernetes] Setting up cloudflare origin ca issuer..."
  CLOUDFLARE_CA_KEY="$(prompt "Enter your cloudflare origin ca key (see https://dash.cloudflare.com/profile/api-tokens):" --secret)"
  
  # prepare origin issuer yaml
  echo "
  apiVersion: cert-manager.k8s.cloudflare.com/v1
  kind: OriginIssuer
  metadata:
    name: "${ORIGIN_CA_ISSUER_NAME}"
    namespace: default
  spec:
    requestType: OriginECC
    auth:
      serviceKeyRef:
        name: "${ORIGIN_CA_ISSUER_SECRET_NAME}"
        key: key
  " > $ISSUER_TEMP_YAML

  # remove old secret
  microk8s kubectl delete secret --ignore-not-found -n default "${ORIGIN_CA_ISSUER_SECRET_NAME}"

  # [!NOTE] see https://github.com/cloudflare/origin-ca-issuer
  microk8s kubectl create secret generic -n default "${ORIGIN_CA_ISSUER_SECRET_NAME}" --from-literal key="${CLOUDFLARE_CA_KEY}"
  microk8s kubectl apply -f $ISSUER_TEMP_YAML

  # remove the temporary file
  rm $ISSUER_TEMP_YAML
}

uninstall_cert_manager() {
  log "[Kubernetes] Uninstalling cert-manager..."
  microk8s helm3 uninstall cert-manager -n cert-manager

  for RESOURCE in "${ORIGIN_CA_ISSUER_RESOURCES[@]}"; do
    microk8s kubectl delete --ignore-not-found -f https://raw.githubusercontent.com/cloudflare/origin-ca-issuer/${ORIGIN_CA_ISSUER_VERSION}/deploy/$RESOURCE
  done

  microk8s kubectl delete secret --ignore-not-found -n default "$ORIGIN_CA_ISSUER_SECRET_NAME"
  microk8s kubectl delete originissuer --ignore-not-found -n default "$ORIGIN_CA_ISSUER_NAME"
}

# installs an ingress controller that routes traffic to services in the cluster
# depending on the host and path of the request (requires cert-manager for tls)
install_ingress_controller() {
  log "[Kubernetes] Installing ingress controller..."
  microk8s kubectl apply -f ${INGRESS_CONTROLLER_RESOURCE}
}

uninstall_ingress_controller() {
  log "[Kubernetes] Uninstalling ingress controller..."
  microk8s kubectl delete -f ${INGRESS_CONTROLLER_RESOURCE}
}

# prompts user for docker credentials and sets up a registry secret in kubernetes
configure_docker_credentials() {
  log "[Kubernetes] Setting up docker-registry secret \"${DOCKER_REGISTRY_SECRET_NAME}\" in the default namespace..."
  SETUP_DOCKER_CREDENTIALS="$(prompt "Do you want to setup docker credentials? [y/N]")"

  if [[ $SETUP_DOCKER_CREDENTIALS =~ ^[Yy]$ ]]; then
    DOCKER_REGISTRY="$(prompt "Enter your docker registry (leave empty for \"${DOCKER_DEFAULT_REGISTRY}\"):")"
    DOCKER_USERNAME="$(prompt "Enter your docker username:")"
    DOCKER_PASSWORD="$(prompt "Enter your docker password:" --secret)"

    if [ -z "$DOCKER_REGISTRY" ]; then
      DOCKER_REGISTRY="${DOCKER_DEFAULT_REGISTRY}"
    fi

    microk8s kubectl create secret docker-registry ${DOCKER_REGISTRY_SECRET_NAME} \
      --docker-server="${DOCKER_REGISTRY}" \
      --docker-username="${DOCKER_USERNAME}" \
      --docker-password="${DOCKER_PASSWORD}"
  fi
}

setup() {
  check_sudo

  case $1 in
    --k8)
      install_microk8s
      ;;
    --cert)
      install_cert_manager
      ;;
    --ingress)
      install_ingress_controller
      ;;
    *)

      if [ -n "$1" ]; then
        log ERROR "[Kubernetes] Invalid option: $1"
        usage
      else
        apt update
        install_snap
        install_microk8s
        install_cert_manager
        install_ingress_controller
        configure_docker_credentials
        
        # run uninstall if setup fails
        if [ $? -ne 0 ]; then
          log ERROR "[Kubernetes] Setup failed. Running teardown..."
          teardown
        else
          log "[MicroK8s] Setup complete!"
        fi
      fi
  esac
}

teardown() {
  case $1 in
    --k8)
      uninstall_microk8s
      ;;
    --cert)
      uninstall_cert_manager
      ;;
    --ingress)
      uninstall_ingress_controller
      ;;
    *)
      if [ -n "$1" ]; then
        log ERROR "[Kubernetes] Invalid option: $1"
        usage
      else
        uninstall_cert_manager
        uninstall_ingress_controller
        uninstall_microk8s
        log "[MicroK8s] Teardown complete!"
      fi
  esac
}

# == SCRIPTS ==================================================================

case $1 in
  start)
    setup $2
    ;;
  stop)
    teardown $2
    ;;
  *)
    usage
    ;;
esac
