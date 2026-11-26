# Quisk SDR Amateur Radio Station

A cross-distribution packaging and configuration suite for running a **Quisk**-centered Software Defined Radio (SDR) amateur radio station on Debian-based (Debian, Ubuntu, Raspberry Pi OS) and RedHat-based (Fedora, RHEL, Rocky, Alma) Linux systems.

This repository compiles a custom fork of **Quisk** (vendored via `git subtree`) and bundles it with pre-configured **PipeWire** virtual audio buses, a **Carla** audio preprocessing rack (EQ, compression, noise gate), `udev` hardware rules, and XDG desktop autostart integration.

---

## Architecture Overview

* **Quisk (`subtrees/quisk`):** Vendored via `git subtree` from a custom fork, compiled from source, and packaged to cleanly provide/replace the system `quisk` package.
* **PipeWire + PulseAudio Compatibility (`pipewire-pulse` & `pipewire-jack`):** Creates persistent virtual audio sinks/sources (`ham_mic_processed`, `ham_radio_rx`, and `ham_digital_tx`) without device-locking conflicts.
* **Carla (`carla-station.desktop`):** Launches automatically into the desktop system tray via `pw-jack` on login to process microphone audio before feeding Quisk's TX input.

---

## Quick Start (Automated Build & Install)

Clone the repository and run the bootstrap script to build the native package (`.deb` or `.rpm`), install all dependencies, and configure your current user:

```bash
git clone https://github.com
cd linux-ham-shack
./scripts/install.sh
```

---

## Manual Package Build & Installation

If you prefer to build and install the system package manually without running `scripts/install.sh`:

### Debian / Ubuntu / Raspberry Pi OS (`.deb`)

1. **Install build dependencies:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y devscripts debhelper equivs
   sudo mk-build-deps -i -r -t "apt-get -y" packaging/debian/control
   ```
2. **Stage `debian/` and build the `.deb` package:**
   ```bash
   cp -a packaging/debian ./debian
   dpkg-buildpackage -us -uc -b
   rm -rf ./debian
   ```
3. **Install the generated package and runtime dependencies:**
   ```bash
   sudo apt-get install -y ../linux-ham-shack_*.deb
   ```

### Fedora / RHEL / Rocky Linux (`.rpm`)

*(Note: On RHEL/Rocky/Alma, ensure the **EPEL** repository is enabled first.)*

1. **Install build dependencies:**
   ```bash
   sudo dnf install -y rpm-build rpmdevtools dnf-plugins-core
   sudo dnf builddep -y packaging/rpm/linux-ham-shack.spec
   ```
2. **Build the `.rpm` package:**
   ```bash
   rpmbuild -bb --define "_topdir \$(pwd)/rpmbuild" \
                --define "_sourcedir \$(pwd)" \
                --build-in-place \
                packaging/rpm/linux-ham-shack.spec
   ```
3. **Install the generated package and runtime dependencies:**
   ```bash
   sudo dnf install -y rpmbuild/RPMS/*/linux-ham-shack-*.rpm
   ```

---

## User Station Setup

Because Linux system packages cannot modify files inside `/home`, a dedicated user initialization command (`quisk-station-init`) is installed to `/usr/bin/`.

Run this command **as your normal radio operator user (not `root`)**:

```bash
quisk-station-init
```

### What `quisk-station-init` Does:
1. **Hardware Permissions:** Adds your user to the `dialout` and `audio` groups for USB SDR and serial CAT access *(requires logging out and back in the first time)*.
2. **Safe Backups:** Backs up any existing `~/.config/pipewire`, `~/.config/carla`, or `~/.config/quisk` folders into `~/.config/linux-ham-shack-backup-<timestamp>/`.
3. **Config Deployment:** Installs the default PipeWire virtual sink definitions, Carla rack patchbay (`station-rack.carxp`), Quisk configuration (`quisk_conf.py`), and desktop/autostart `.desktop` entries.
4. **Service Activation:** Restarts PipeWire and WirePlumber user services so the virtual audio devices appear immediately.

---

## Launching the Station

1. **Verify the Audio Backend (Carla + PipeWire):**
   Carla starts automatically minimized to your system tray on desktop login via `~/.config/autostart/carla-station.desktop`. To launch it immediately without logging out, run:
   ```bash
   pw-jack carla ~/.config/carla/station-rack.carxp &
   ```
   Click the Carla system tray icon at any time to open the patchbay and tweak plugin settings.

2. **Launch Quisk:**
   Start **Quisk SDR Station** from your desktop application menu or from a terminal:
   ```bash
   quisk
   ```

### Virtual Audio Routing Reference

| Virtual Device Name | Purpose | Quisk / App Assignment |
| :--- | :--- | :--- |
| **`Ham Mic Processed`** | Pre-processed voice audio out of Carla | Set Quisk **Mic Input** to `Monitor of Ham Mic Processed` |
| **`Ham Radio RX Audio`** | Demodulated receiver audio from Quisk | Set Quisk **Radio Sound Output** to `Ham Radio RX Audio` |
| **`Ham Digital TX Audio`** | TX audio from WSJT-X / fldigi | Set WSJT-X **Output** to `Ham Digital TX Audio` |

---

## Managing the Quisk Subtree

### Initial Setup (One-Time)
```bash
git remote add quisk-fork https://github.com
git subtree add --prefix=subtrees/quisk quisk-fork main --squash
```

### Pulling Updates from Your Quisk Fork
```bash
git subtree pull --prefix=subtrees/quisk quisk-fork main --squash
```

### Pushing Quisk-Only Changes Back to Your Fork
If you make a bugfix or feature improvement inside `subtrees/quisk/` while working on your station, push just that directory back to a clean branch on your fork for upstream PRs:
```bash
git subtree push --prefix=subtrees/quisk quisk-fork my-feature-branch
```
