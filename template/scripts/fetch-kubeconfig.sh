#!/usr/bin/env bash
# Fetches the kubeconfig from the remote cluster
set -euo pipefail

REMOTE_KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
LOCAL_KUBECONFIG_PATH="./k3s-kubeconfig.yaml"

# Set root dir to the directory of the script
cd "$(dirname "$0")/.."

if [ -z "${SSH_PRIVATE_KEY_FILE}" ]; then
  echo "SSH_PRIVATE_KEY_FILE is not set"
  exit 1
fi

if [ -z "${SSH_USER}" ]; then
  echo "SSH_USER is not set"
  exit 1
fi

# Get the cluster IP from terraform output
IP=$(cd terraform && terraform output -raw primary_control_plane_ip)

echo "Fetching kubeconfig from the cluster"

scp \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -i "${SSH_PRIVATE_KEY_FILE}" "${SSH_USER}@${IP}":"${REMOTE_KUBECONFIG_PATH}" \
  "${LOCAL_KUBECONFIG_PATH}"

sed -i "s|server: https://.*|server: https://${IP}:6443|" "${LOCAL_KUBECONFIG_PATH}"

chmod 644 "${LOCAL_KUBECONFIG_PATH}"

echo "Kubeconfig fetched successfully"
