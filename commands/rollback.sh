#!/usr/bin/env bash

# VirtualBox Auto-Resize Workaround
# Rollback Script
# Author: Kalam Ilyass

set -euo pipefail

TARGET="/usr/bin/VBoxDRMClient"
BACKUP="/usr/bin/VBoxDRMClient.real"

echo "=========================================="
echo " VirtualBox Auto-Resize Rollback"
echo "=========================================="

# 1. Check current diversion
CURRENT=$(dpkg-divert --truename "$TARGET")

if [[ "$CURRENT" == "$TARGET" ]]; then
    echo "[INFO] No workaround detected."
    exit 0
fi

# 2. Verify expected diversion
if [[ "$CURRENT" != "$BACKUP" ]]; then
    echo "[ERROR] Unexpected diversion detected."
    exit 1
fi

# 3. Check backup file
if [[ ! -f "$BACKUP" ]]; then
    echo "[ERROR] Original executable backup not found."
    exit 1
fi

# 4. Avoid overwriting an existing executable
if [[ -e "$TARGET" ]]; then
    echo "[ERROR] Target executable already exists."
    echo "[INFO] No changes were made."
    exit 1
fi

# 5. Request confirmation
echo "[WARNING] This will restore the original executable."
read -r -p "Continue with rollback? [y/N]: " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "[INFO] Rollback cancelled."
    exit 0
fi

# 6. Remove diversion and restore original file
sudo dpkg-divert --remove --rename \
    --divert "$BACKUP" "$TARGET"

# 7. Verify restoration
if [[ -f "$TARGET" ]] && \
   [[ "$(dpkg-divert --truename "$TARGET")" == "$TARGET" ]]; then
    echo "[SUCCESS] Original executable restored."
else
    echo "[ERROR] Restoration verification failed."
    exit 1
fi

echo "[INFO] Rollback completed."
