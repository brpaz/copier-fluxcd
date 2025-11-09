#!/usr/bin/env bash
# Initializes the Kubernetes cluster core components
# This includes installing the Hetzner Cloud Controller Manager and Cilium

set -eo pipefail

CILIUM_VERSION="1.18.3"
HCLOUD_NS="hcloud"

# ANSI color codes
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print cyan colored message
function info() {
  echo -e "${CYAN}$1${NC}"
}

# Function to print red colored error message
function error() {
  echo -e "${RED}$1${NC}" >&2
}

# Function to check if can connect to the Kubernetes cluster and exit if not
function check_kube_connection() {
  info "Checking Kubernetes connection..."
  kubectl get nodes >/dev/null
  info "Kubernetes connection verified."
}

# Function to install Hetzner Cloud Controller Manager in the cluster
function install_hccm() {
  info "Installing Hetzner Cloud Controller Manager..."

  # Add Hetzner Helm repo if not added
  if ! helm repo list | grep -q "hcloud"; then
    helm repo add hcloud https://charts.hetzner.cloud
    helm repo update
  fi

  # Create namespace if not exists
  kubectl get ns "${HCLOUD_NS}" &>/dev/null || kubectl create ns "${HCLOUD_NS}"

  # Create secret if not exists
  kubectl -n "${HCLOUD_NS}" create secret generic hcloud --from-literal=token="${HCLOUD_TOKEN}" --dry-run=client -o yaml | kubectl apply -f -

  # Install HCCM
  helm upgrade --install hccm hcloud/hcloud-cloud-controller-manager -n "${HCLOUD_NS}"

  # Wait for HCCM deployment
  info "Waiting for Hetzner Cloud Controller Manager to be ready..."
  kubectl wait --for=condition=available --timeout=1m deployment/hcloud-cloud-controller-manager -n "${HCLOUD_NS}"
  info "Hetzner Cloud Controller Manager installed and ready."
}

# Function to install Cilium
function install_cilium() {
  info "Installing Cilium version ${CILIUM_VERSION}..."
  cilium install --version "${CILIUM_VERSION}"
  cilium status --wait

  info "Cilium installed and verified."
}

# Main script logic

# Check dependencies
for cmd in kubectl helm cilium; do
  if ! command -v "$cmd" &>/dev/null; then
    error "Error: '$cmd' command not found. Please install it and retry."
    exit 1
  fi
done

# Check for required environment variables
if [ -z "${HCLOUD_TOKEN}" ]; then
  error "Error: HCLOUD_TOKEN is not set. Please set HCLOUD_TOKEN environment variable."
  exit 1
fi

# Start the installation process
check_kube_connection

install_cilium

install_hccm

info "Kubernetes cluster initialization completed successfully."
