#!/usr/bin/env bash
#
# EXPERIMENTAL: VirtualBox VBoxDRMClient diversion
# Author: Kalam Ilyass
#
# This script demonstrates a dpkg-divert experiment. It is NOT a generally
# recommended fix. The repository's final successful resize test was performed
# after restoring the original VBoxDRMClient path; causality was not established.

set -euo pipefail

TARGET="/usr/bin/VBoxDRMClient"
BACKUP="/usr/bin/VBoxDRMClient.real"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log "ERROR" "$1" >&2; exit 1; }

[[ $EUID -eq 0 ]] && fail "Do not run this script as root; run it as a regular user so sudo can prompt interactively."

for cmd in systemd-detect-virt dpkg-divert sudo; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Required command not found: $cmd"
done

VIRT="$(systemd-detect-virt || true)"
[[ "$VIRT" == "oracle" ]] || fail "Oracle VirtualBox guest not detected (detected: ${VIRT:-none})."

[[ "${XDG_SESSION_TYPE:-}" == "x11" ]] || fail "This experiment was documented for X11 only."

CURRENT="$(dpkg-divert --truename "$TARGET")"
if [[ "$CURRENT" == "$BACKUP" && -f "$BACKUP" ]]; then
    log "INFO" "The expected diversion is already present; no change made."
    exit 0
fi
[[ "$CURRENT" == "$TARGET" ]] || fail "An unexpected diversion exists: $CURRENT"
[[ -f "$TARGET" ]] || fail "Original executable not found: $TARGET"
[[ ! -e "$BACKUP" ]] || fail "Backup path already exists: $BACKUP"

cat <<'WARNING'
WARNING: EXPERIMENTAL PACKAGE-FILE CHANGE
This operation moves a package-managed executable using dpkg-divert.
It may affect VirtualBox guest display integration and may cause instability.
A VM snapshot and a tested rollback path are strongly recommended.
This experiment is not known to be the cause of the successful resize result
documented in this repository.
WARNING

read -r -p "Continue with this experiment? Type YES to proceed: " CONFIRM
[[ "$CONFIRM" == "YES" ]] || { log "INFO" "Cancelled; no changes made."; exit 0; }

sudo dpkg-divert --add --rename --divert "$BACKUP" "$TARGET"

CURRENT="$(dpkg-divert --truename "$TARGET")"
if [[ "$CURRENT" == "$BACKUP" && -f "$BACKUP" && ! -e "$TARGET" ]]; then
    log "SUCCESS" "Diversion registered. Original executable preserved at $BACKUP"
    log "INFO" "Reboot and test only if you understand the risk. Use commands/rollback.sh to revert."
else
    log "ERROR" "Post-change verification failed. Inspect diversion and files before proceeding."
    exit 1
fi
