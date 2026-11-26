#!/usr/bin/env bash
#
# Kali Linux / VirtualBox Auto-Resize diagnostic collector
# Author: Kalam Ilyass
#
# Read-only: this script gathers information and does not change system settings.

set -u

section() {
    printf '\n==========================================\n'
    printf ' %s\n' "$1"
    printf '==========================================\n'
}

run_check() {
    local label="$1"
    shift
    printf '\n--- %s ---\n' "$label"
    if command -v "$1" >/dev/null 2>&1; then
        "$@" 2>&1 || printf '[INFO] Command returned a non-zero status.\n'
    else
        printf '[INFO] Required command not found: %s\n' "$1"
    fi
}

section "VirtualBox Auto-Resize Diagnostics"

section "1. System information"
run_check "Kernel" uname -r
run_check "OS release" cat /etc/os-release
printf '\nArchitecture: '
run_check "Architecture" dpkg --print-architecture

section "2. Desktop session"
printf 'XDG_CURRENT_DESKTOP=%s\n' "${XDG_CURRENT_DESKTOP:-not-set}"
printf 'XDG_SESSION_TYPE=%s\n' "${XDG_SESSION_TYPE:-not-set}"
printf 'DISPLAY=%s\n' "${DISPLAY:-not-set}"
printf 'XDG_RUNTIME_DIR=%s\n' "${XDG_RUNTIME_DIR:-not-set}"

section "3. VirtualBox kernel modules"
run_check "Loaded VirtualBox modules" bash -c "lsmod | grep -E 'vboxguest|vboxsf|vboxvideo' || true"

section "4. Guest Additions packages"
run_check "Installed guest packages" bash -c "dpkg -l | grep -E 'virtualbox-guest|^ii  virtualbox' || true"

section "5. Guest Additions command-line version"
run_check "VBoxControl version" VBoxControl --version

section "6. Display configuration"
run_check "Connected displays and modes" xrandr --current

section "7. VirtualBox processes"
run_check "VBoxService and VBoxClient processes" bash -c "pgrep -a 'VBoxService|VBoxClient|VBoxDRMClient' || true"

section "8. VBoxDRMClient ownership"
run_check "Process ownership" ps -C VBoxDRMClient -o user,pid,ppid,args

section "9. Guest Additions service"
run_check "Service status" systemctl status virtualbox-guest-utils.service --no-pager

section "10. Recent Guest Additions service logs"
run_check "Recent service journal" journalctl -b -u virtualbox-guest-utils.service --no-pager -n 40

section "11. Package diversion state"
run_check "VBoxDRMClient diversion" dpkg-divert --list
run_check "Resolved executable path" dpkg-divert --truename /usr/bin/VBoxDRMClient

section "12. VBoxDRMClient files"
run_check "Executable metadata" ls -l /usr/bin/VBoxDRMClient /usr/bin/VBoxDRMClient.real

section "Diagnostics completed"
printf 'No system settings were modified by this script.\n'
