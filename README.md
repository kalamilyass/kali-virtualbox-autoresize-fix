
# Kali Linux on VirtualBox – Auto-Resize Troubleshooting

![Platform](https://img.shields.io/badge/Platform-Kali%20Linux-blue)
![Virtualization](https://img.shields.io/badge/Virtualization-VirtualBox-orange)
![Desktop](https://img.shields.io/badge/Desktop-XFCE-teal)
![Status](https://img.shields.io/badge/Status-Tested-success)

## 1. Project Overview

This project documents the investigation and resolution of an automatic display resizing issue affecting Kali Linux running inside Oracle VirtualBox.

The objective was to restore automatic screen resolution adjustment when resizing the virtual machine window, without reinstalling the Guest Additions packages.

The investigation included Linux process analysis, service inspection, display configuration diagnostics, and package file management using `dpkg-divert`.

## 2. Environment

| Component | Version / Configuration |
|---|---|
| Operating System | Kali Linux Rolling |
| Kernel | 6.16.8+kali-amd64 |
| Virtualization | Oracle VirtualBox |
| Guest Additions | 7.2.8 |
| Desktop Environment | XFCE |
| Display Server | X11 |
| Display Adapter | Virtual-1 |

## 3. Problem Description

The following symptoms were observed:

- Automatic display resizing was not working.
- The desktop remained at an inappropriate resolution.
- Horizontal and vertical scrollbars appeared.
- Resizing the VirtualBox window did not correctly adjust the guest display.
- Guest Additions were already installed.

## 4. Initial Investigation

### 4.1 Identify the Desktop Environment

```bash
echo $XDG_CURRENT_DESKTOP
echo $XDG_SESSION_TYPE
```

Expected environment:

```text
XFCE
x11
```

### 4.2 Verify Guest Additions

```bash
dpkg -l | grep virtualbox-guest
VBoxControl --version
```

### 4.3 Check Kernel Modules

```bash
lsmod | grep -i vbox
```

### 4.4 Inspect Display Configuration

```bash
xrandr --current
```

The virtual display was identified as `Virtual-1`.

### 4.5 Inspect VirtualBox Processes

```bash
pgrep -a VBoxService
pgrep -a VBoxClient
pgrep -a VBoxDRMClient
```

The investigation identified:

- VBoxDRMClient
- VBoxClient --vmsvga-session
- VBoxService

Further process inspection showed that VBoxDRMClient was running under the root account.

```bash
ps -fp <PID>
```

## 5. Service Investigation

The Guest Additions service was inspected using:

```bash
systemctl status virtualbox-guest-utils.service --no-pager
```

The service configuration was examined with:

```bash
systemctl cat virtualbox-guest-utils.service
```

The initialization script was also inspected:

```bash
sudo sed -n '1,240p' /etc/init.d/virtualbox-guest-utils
```

This helped identify how VirtualBox Guest Additions initialized the display services.

## 6. Implemented Workaround

A similar display resizing issue was documented in the Debian Bug Tracker.

Reference:
https://bugs.debian.org/1143862

The workaround tested in this environment used `dpkg-divert` to move the original VBoxDRMClient executable to an alternative filename.

### 6.1 Apply the Diversion

```bash
sudo dpkg-divert --add --rename \
  --divert /usr/bin/VBoxDRMClient.real \
  /usr/bin/VBoxDRMClient
```

### 6.2 Understand the Command

| Option | Description |
|---|---|
| sudo | Execute with administrative privileges |
| dpkg-divert | Manage diversions of package files |
| --add | Register a new diversion |
| --rename | Rename the original file |
| --divert | Specify the alternative file path |

The original executable is preserved as:

```text
/usr/bin/VBoxDRMClient.real
```

### 6.3 Verify the Diversion

```bash
dpkg-divert --list | grep VBoxDRMClient
```

Expected output:

```text
local diversion of /usr/bin/VBoxDRMClient to /usr/bin/VBoxDRMClient.real
```

Check the original file:

```bash
ls -l /usr/bin/VBoxDRMClient*
```

## 7. Validation After Restart

After applying the workaround, the virtual machine was restarted.

The following command was used to inspect the running processes:

```bash
pgrep -a 'VBoxDRMClient|VBoxClient'
```

Observed results:

- VBoxDRMClient was no longer running.
- VBoxClient --vmsvga was running.
- Clipboard processes remained available.
- Seamless and Drag-and-Drop processes remained available.

The automatic display resizing functionality was then tested by changing the VirtualBox window size.

**Result:** Automatic display resizing worked correctly after restarting the virtual machine.

## 8. Rollback Procedure

If the workaround needs to be reverted, use:

```bash
sudo dpkg-divert --remove --rename \
  --divert /usr/bin/VBoxDRMClient.real \
  /usr/bin/VBoxDRMClient
```

This removes the local diversion and restores the original executable path.

**Important:** Do not manually delete `VBoxDRMClient.real`.

## 9. Technical Lessons Learned

This troubleshooting exercise provided practical experience in:

- Linux process inspection and management.
- VirtualBox Guest Additions.
- XFCE and X11 display management.
- Linux service investigation using systemd.
- Package file management with dpkg-divert.
- Bash command-line troubleshooting.
- Testing and validating changes after system reboot.
- Writing technical documentation.

## 10. Conclusion

The display resizing issue was successfully resolved in the tested Kali Linux environment using a local `dpkg-divert` workaround.

The original executable was preserved, and the display behavior was verified after restarting the virtual machine.

This is a tested workaround for the documented environment, not an official upstream fix. Results may vary depending on VirtualBox and Guest Additions versions.

## 11. References

- Debian Bug Tracker: https://bugs.debian.org/1143862
- Oracle VirtualBox Documentation: https://www.virtualbox.org/manual/
- Debian dpkg-divert Manual: https://manpages.debian.org/dpkg-divert

---

**Author:** Kalam Ilyass

**Project:** Kali Linux VirtualBox Auto-Resize Troubleshooting

**Category:** Linux Administration | Virtualization | Troubleshooting
