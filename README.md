# Kali Linux VirtualBox Auto-Resize Troubleshooting Toolkit

![Platform](https://img.shields.io/badge/platform-Kali%20Linux-blue)
![Virtualization](https://img.shields.io/badge/virtualization-VirtualBox-orange)
![Shell](https://img.shields.io/badge/language-Bash-4EAA25)
![Status](https://img.shields.io/badge/status-investigated%20%7C%20validated-informational)

A practical Bash-based toolkit and case study for diagnosing automatic display-resizing problems in Kali Linux guests running on Oracle VirtualBox.

> **Scope and honesty:** this repository documents one real troubleshooting session. The final resize test passed after restoring the original `VBoxDRMClient` executable and using VirtualBox's **View → Auto-resize Guest Display** option. The session does **not** establish that the `dpkg-divert` workaround caused the fix. The diversion-based script is therefore retained as experimental and is not recommended as a default fix.

## Contents

- [Problem](#problem)
- [Test environment](#test-environment)
- [Observed investigation](#observed-investigation)
- [Final validation](#final-validation)
- [Repository structure](#repository-structure)
- [Usage](#usage)
- [Experimental workaround and rollback](#experimental-workaround-and-rollback)
- [Safety notes](#safety-notes)
- [Limitations](#limitations)
- [References](#references)

## Problem

The Kali Linux desktop did not consistently adapt its resolution to the VirtualBox window. The guest display was observed at different dimensions while the VM window was resized.

The purpose of this project is to make the investigation repeatable: collect system facts, inspect Guest Additions and display services, record the observed behavior, and preserve a rollback path for any experimental package-file change.

## Test environment

| Component | Observed value |
|---|---|
| Guest OS | Kali GNU/Linux Rolling (reported as 2025.4) |
| Kernel | `6.16.8+kali-amd64` |
| Desktop | XFCE |
| Display session | X11 |
| Virtual display | `Virtual-1` |
| Guest Additions packages | `virtualbox-guest-utils`, `virtualbox-guest-x11` |
| Guest Additions package version | `7.2.8` |
| VirtualBox guest modules | `vboxguest`, `vboxsf` |

These are values from the tested machine, not universal requirements.

## Observed investigation

The troubleshooting session used the following checks:

| Area | Commands / evidence |
|---|---|
| OS and kernel | `uname -r`, `cat /etc/os-release` |
| Desktop session | `echo "$XDG_CURRENT_DESKTOP"`, `echo "$XDG_SESSION_TYPE"` |
| Guest packages | `dpkg -l | grep virtualbox-guest` |
| Kernel modules | `lsmod | grep -E 'vboxguest|vboxsf'` |
| Display modes | `xrandr --current` |
| Guest processes | `pgrep -a 'VBoxDRMClient|VBoxClient'` |
| Process ownership | `ps -eo user,pid,ppid,args | grep -E '[V]Box(Client|DRMClient)'` |
| Guest service | `systemctl status virtualbox-guest-utils.service --no-pager` |
| Service logs | `journalctl -b -u virtualbox-guest-utils.service --no-pager -n 80` |
| Package diversion | `dpkg-divert --truename /usr/bin/VBoxDRMClient` |

### Important observations

- The guest was using X11, not Wayland.
- The `VBoxClient --vmsvga` process was already running; a manually launched second instance reported that the service was already running.
- The Guest Additions service log included `XDG_RUNTIME_DIR is invalid or not set` during service startup and `VMSVGA DRM resizing client not started, rc=VERR_FILE_NOT_FOUND`. These messages were recorded as diagnostic evidence; their causal relationship to the symptom was not established.
- `VBoxControl guestproperty` commands returned “Could not contact the host system” during the session.
- The kernel log reported host version `7.1.6r167084`, while the installed guest packages reported version `7.2.8`. This version difference is worth checking in future reproductions; it is not, by itself, proof of the root cause.
- A VirtualBox application error occurred during one test involving the display-resize setting. The original executable was subsequently restored.

## Final validation

The original executable was restored using the rollback command documented below. The VirtualBox **Auto-resize Guest Display** option was then enabled for the final window-resize test.

Observed guest resolutions:

| VM window state | `xrandr` reported resolution |
|---|---:|
| Smaller window | `955x925` |
| Maximized window | `1920x937` |

The guest resolution changed with the VirtualBox window size in this final test.

**What this proves:** automatic resizing worked in this tested configuration at the time of the final check.

**What this does not prove:** that the experimental `dpkg-divert` change fixed the issue. The final successful test was performed after the original `VBoxDRMClient` path had been restored. No controlled A/B test isolated a single root cause.

## Repository structure

```text
.
├── commands/
│   ├── diagnostics.sh
│   └── rollback.sh
├── experimental/
│   └── fix.sh
├── docs/
│   └── test-results.md
├── .gitignore
├── LICENSE
└── README.md
```

## Usage

Clone the repository:

```bash
git clone https://github.com/kalamilyass/kali-virtualbox-autoresize-fix.git
cd kali-virtualbox-autoresize-fix
```

Run the read-only diagnostic script:

```bash
bash commands/diagnostics.sh
```

The script collects information only. It does not install packages, change display settings, stop processes, or modify package files.

For a quick manual display check:

```bash
xrandr --current
```

In the VirtualBox VM window, check **View → Auto-resize Guest Display** and resize the VM window. Compare the reported dimensions after each change.

## Experimental workaround and rollback

The script `experimental/fix.sh` demonstrates a local package diversion of `/usr/bin/VBoxDRMClient` using `dpkg-divert`. It is preserved for study and reproducibility only.

**Do not run it as a routine fix.** It changes a package-managed executable path, and this project has not established that the change is necessary or beneficial for the final working configuration. Create a VM snapshot first and understand the rollback procedure before experimenting.

If the diversion is present and points to `/usr/bin/VBoxDRMClient.real`, the corresponding rollback is:

```bash
sudo dpkg-divert --remove --rename \
  --divert /usr/bin/VBoxDRMClient.real \
  /usr/bin/VBoxDRMClient
```

Then verify the restored path:

```bash
dpkg-divert --truename /usr/bin/VBoxDRMClient
ls -l /usr/bin/VBoxDRMClient
```

Expected `--truename` output when no diversion remains:

```text
/usr/bin/VBoxDRMClient
```

The included `commands/rollback.sh` checks the expected diversion and backup file and asks for confirmation before attempting restoration. Review the script before running it.

## Safety notes

- Take a VirtualBox snapshot before any experiment that changes system files.
- Read scripts before running them; use elevated privileges only when required.
- The diagnostic script is intended to be read-only.
- The experimental workaround is not an official Oracle, Kali, or Debian fix.
- Do not delete `VBoxDRMClient.real` manually.
- Avoid claiming a root cause unless a controlled test confirms it.

## Limitations

- Validation was performed on one Kali/VirtualBox configuration.
- The repository does not yet include automated integration tests against multiple VirtualBox and Guest Additions versions.
- The final successful resize test is an observed result, not proof of a universal fix.
- The Debian bug reference below is related background, not proof that this machine had the same root cause.

## References

- [Oracle VirtualBox User Manual](https://www.virtualbox.org/manual/)
- [Debian Bug #1143862](https://bugs.debian.org/1143862) — related issue reference examined during troubleshooting
- [Debian dpkg-divert manual](https://manpages.debian.org/dpkg-divert)

## Author

**Kalam Ilyass**  
Linux Administration · Bash Scripting · Virtualization · Troubleshooting
