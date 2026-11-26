#!/usr/bin/env bash

# Kali Linux VirtualBox Auto-Resize Diagnostics
# Author: Kalam Ilyass
# Read-only diagnostic script

echo "=========================================="
echo " VirtualBox Auto-Resize Diagnostics"
echo "=========================================="

echo -e "\n[1] System Information"
uname -r
cat /etc/os-release

echo -e "\n[2] Desktop Environment"
echo "Desktop: $XDG_CURRENT_DESKTOP"
echo "Session: $XDG_SESSION_TYPE"

echo -e "\n[3] VirtualBox Kernel Modules"
lsmod | grep -i vbox

echo -e "\n[4] Guest Additions Packages"
dpkg -l | grep virtualbox-guest

echo -e "\n[5] Guest Additions Version"
VBoxControl --version

echo -e "\n[6] Display Configuration"
xrandr --current

echo -e "\n[7] Running VirtualBox Processes"
pgrep -a 'VBoxDRMClient|VBoxClient|VBoxService'

echo -e "\n[8] Process Ownership"
ps -C VBoxDRMClient -o user,pid,ppid,args

echo -e "\n[9] Guest Additions Service"
systemctl status virtualbox-guest-utils.service --no-pager

echo -e "\n[10] Checking Package Diversions"
dpkg-divert --list | grep VBoxDRMClient

echo -e "\n[11] Checking Executable Files"
ls -l /usr/bin/VBoxDRMClient*

echo -e "\n=========================================="
echo " Diagnostics completed."
echo " No system settings were modified."
echo "=========================================="
