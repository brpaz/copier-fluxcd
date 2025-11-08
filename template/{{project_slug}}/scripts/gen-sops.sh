#!/usr/bin/env bash
# Setups SOPS for the project

set -euo pipefail

KEY_NAME=${KEY_NAME:-"cluster0.yourdomain.com"}
KEY_COMMENT=${KEY_COMMENT:-"${KEY_NAME} SOPS key"}

gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Expire-Date: 0
Name-Comment: ${KEY_COMMENT}
Name-Real: ${KEY_NAME}
EOF

echo "SOPS GPG key generated:"
echo "Fingerprint:"
gpg --list-keys --with-colons "${KEY_NAME}" | grep '^fpr' | cut -d: -f10
