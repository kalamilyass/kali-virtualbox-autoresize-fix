#!/usr/bin/env bash

# VirtualBox Auto-Resize Workaround
# Author: Kalam Ilyass
# Tested environment: Kali Linux, XFCE, X11
# Guest Additions: 7.2.8
# Reference: https://bugs.debian.org/1143862

set -euo pipefail

TARGET="/usr/bin/VBoxDRMClient"
BACKUP="/usr/bin/VBoxDRMClient.real"

echo "=========================================="
echo " VirtualBox Auto-Resize Fix"
echo "=========================================="

# 1. Check virtualization environment
if [[ "$(systemd-detect-virt)" != "oracle" ]]; then
    echo "[ERROR] VirtualBox environment not detected."
    exit 1
fi

# 2. Check desktop session
if [[ "${XDG_SESSION_TYPE:-}" != "x11" ]]; then
    echo "[ERROR] This workaround requires an X11 session."
    exit 1
fi

# 3. Check existing diversion
CURRENT=$(dpkg-divert --truename "$TARGET")

if [[ "$CURRENT" == "$BACKUP" && -f "$BACKUP" ]]; then
    echo "[INFO] Workaround already applied."
    exit 0
fi

if [[ "$CURRENT" != "$TARGET" ]]; then
    echo "[ERROR] Another diversion already exists."
    exit 1
fi

# 4. Check required files
if [[ ! -f "$TARGET" || -e "$BACKUP" ]]; then
    echo "[ERROR] Unexpected executable state."
    exit 1
fi

# 5. Request confirmation
echo "[WARNING] This workaround modifies a package file path."
echo "[INFO] Create a VM snapshot before continuing."
echo "[INFO] Compatibility with other versions is not guaranteed."

read -r -p "Apply the workaround? [y/N]: " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "[INFO] Operation cancelled."
    exit 0
fi

# 6. Apply package diversion
sudo dpkg-divert --add --rename \
    --divert "$BACKUP" "$TARGET"

# 7. Verify the result
if [[ "$(dpkg-divert --truename "$TARGET")" == "$BACKUP" \
      && -f "$BACKUP" && ! -e "$TARGET" ]]; then
    echo "[SUCCESS] Workaround applied."
    echo "[INFO] Original executable preserved at:"
    echo "$BACKUP"
else
    echo "[ERROR] Verification failed."
    exit 1
fi

echo "[INFO] Restart Kali Linux and test auto-resize."
echo "[INFO] See README.md for rollback instructions."
