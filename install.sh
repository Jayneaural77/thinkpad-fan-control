#!/usr/bin/env bash
#
# Installer for ThinkPad Fan Control (daemon + GUI).
# Run with: sudo ./install.sh
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root:  sudo ./install.sh" >&2
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || true)}"
if [[ -z "$REAL_USER" || "$REAL_USER" == "root" ]]; then
    echo "WARNING: could not detect your normal username; config will be owned by root." >&2
    echo "         The GUI may then fail to save. Re-run with sudo from your user session." >&2
    REAL_USER="root"
fi

echo "==> Installing for user: $REAL_USER"

# 1. Make sure thinkpad_acpi exposes writable fan control.
MODCONF=/etc/modprobe.d/thinkpad_acpi.conf
if ! grep -qs "fan_control=1" "$MODCONF" 2>/dev/null; then
    echo "==> Enabling fan_control in $MODCONF"
    echo "options thinkpad_acpi fan_control=1" >> "$MODCONF"
fi

if [[ ! -w /proc/acpi/ibm/fan ]]; then
    echo "==> Reloading thinkpad_acpi module to enable fan control"
    modprobe -r thinkpad_acpi 2>/dev/null || true
    modprobe thinkpad_acpi || true
fi
if [[ ! -w /proc/acpi/ibm/fan ]]; then
    echo "    NOTE: /proc/acpi/ibm/fan still not writable; a reboot may be required." >&2
fi

# 2. Install executables to /usr/bin (canonical; matches the .deb package).
echo "==> Installing executables to /usr/bin"
rm -f /usr/local/bin/thinkpad-fand /usr/local/bin/thinkpad-fan-gui   # clean up older installs
install -m 0755 "$SRC/thinkpad-fand"    /usr/bin/thinkpad-fand
install -m 0755 "$SRC/thinkpad-fan-gui" /usr/bin/thinkpad-fan-gui

# 3. Config directory, owned by the user so the GUI can save atomically.
echo "==> Setting up /etc/thinkpad-fan (owned by $REAL_USER)"
mkdir -p /etc/thinkpad-fan
if [[ ! -f /etc/thinkpad-fan/config.json ]]; then
    install -m 0644 "$SRC/config.json" /etc/thinkpad-fan/config.json
fi
chown -R "$REAL_USER" /etc/thinkpad-fan

# 4. systemd service.
echo "==> Installing and starting the systemd service"
install -m 0644 "$SRC/thinkpad-fand.service" /etc/systemd/system/thinkpad-fand.service
systemctl daemon-reload
systemctl enable thinkpad-fand.service
# restart (not just start) so an upgrade always loads the new binary
systemctl restart thinkpad-fand.service

# 5. Icons (scalable SVG + raster PNG) and desktop launcher.
echo "==> Installing icons and application launcher"
install -d /usr/share/icons/hicolor/scalable/apps
install -d /usr/share/icons/hicolor/256x256/apps
install -d /usr/share/pixmaps
install -m 0644 "$SRC/icon.svg" /usr/share/icons/hicolor/scalable/apps/thinkpad-fan-control.svg
install -m 0644 "$SRC/icon.png" /usr/share/icons/hicolor/256x256/apps/thinkpad-fan-control.png
install -m 0644 "$SRC/icon.png" /usr/share/pixmaps/thinkpad-fan-control.png
install -m 0644 "$SRC/thinkpad-fan-control.desktop" \
    /usr/share/applications/thinkpad-fan-control.desktop
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true

echo
echo "==> Done."
systemctl --no-pager --full status thinkpad-fand.service | head -n 6 || true
echo
echo "Launch the GUI from your app menu ('ThinkPad Fan Control') or run:"
echo "    thinkpad-fan-gui"
