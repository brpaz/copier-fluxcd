#!/usr/bin/env bash
# This script bootstraps Cilium and Flux on a Kubernetes cluster
set -eo pipefail

CLUSTER=${KUBE_CLUSTER:-production}

# Ensure required environment variables are set
for var in GITHUB_TOKEN GITHUB_OWNER GITHUB_REPOSITORY SOPS_PGP_FP; do
  if [[ -z "${!var}" ]]; then
    echo "Error: $var is not set. Exiting..." >&2
    exit 1
  fi
done

if ! command -v kubectl &>/dev/null; then
  echo "Error: 'kubectl' command not found. Install kubectl first: https://kubernetes.io/docs/tasks/tools/install-kubectl/" >&2
  exit 1
fi

# Check if Flux is installed
if ! command -v flux &>/dev/null; then
  echo "Error: 'flux' command not found. Install Flux first: https://toolkit.fluxcd.io/guides/installation/" >&2
  exit 1
fi

flux check --pre

# check if flux-system namespace exists and create it if not
if ! kubectl get ns flux-system >/dev/null 2>&1; then
  kubectl create ns flux-system
fi

if ! kubectl get secret sops-gpg --namespace=flux-system >/dev/null 2>&1; then
  echo "Creating sops-gpg secret..."
  gpg --export-secret-keys --armor "${SOPS_PGP_FP}" |
    kubectl create secret generic sops-gpg \
      --namespace=flux-system \
      --from-file=sops.asc=/dev/stdin
fi

# Bootstrap Flux
flux bootstrap github \
  --owner="$GITHUB_OWNER" \
  --repository="$GITHUB_REPOSITORY" \
  --private=true \
  --personal=true \
  --path="clusters/$CLUSTER" \
  --components-extra=image-reflector-controller,image-automation-controller \
  --version=latest
