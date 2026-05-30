#!/usr/bin/env bash
#
# Build a .deb package for ThinkPad Fan Control.
# Usage: ./build-deb.sh   (produces build/thinkpad-fan-control_<ver>_all.deb)
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="thinkpad-fan-control"
VERSION="1.0.0"
BUILD="$SRC/build"
STAGE="$BUILD/stage"

rm -rf "$BUILD"
mkdir -p "$STAGE"

# --- payload --------------------------------------------------------------- #
install -Dm755 "$SRC/thinkpad-fand"               "$STAGE/usr/bin/thinkpad-fand"
install -Dm755 "$SRC/thinkpad-fan-gui"            "$STAGE/usr/bin/thinkpad-fan-gui"
install -Dm644 "$SRC/thinkpad-fand.service"       "$STAGE/lib/systemd/system/thinkpad-fand.service"
install -Dm644 "$SRC/thinkpad-fan-control.desktop" "$STAGE/usr/share/applications/thinkpad-fan-control.desktop"
install -Dm644 "$SRC/icon.svg"                    "$STAGE/usr/share/icons/hicolor/scalable/apps/thinkpad-fan-control.svg"
install -Dm644 "$SRC/icon.png"                    "$STAGE/usr/share/icons/hicolor/256x256/apps/thinkpad-fan-control.png"
install -Dm644 "$SRC/icon.png"                    "$STAGE/usr/share/pixmaps/thinkpad-fan-control.png"
install -Dm644 "$SRC/config.json"                 "$STAGE/usr/share/thinkpad-fan-control/config.json"
install -Dm644 "$SRC/README.md"                   "$STAGE/usr/share/doc/thinkpad-fan-control/README.md"

# --- control --------------------------------------------------------------- #
INSTALLED_KB=$(du -ks "$STAGE" | cut -f1)
mkdir -p "$STAGE/DEBIAN"
cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: python3, python3-tk
Recommends: lm-sensors
Installed-Size: $INSTALLED_KB
Maintainer: Swmarakis <georgesom7@gmail.com>
Homepage: https://github.com/Swmarakis/thinkpad-fan-control
Description: Automatic fan-speed control for ThinkPad laptops
 A temperature-curve daemon plus a Tkinter GUI to control the fan on ThinkPad
 laptops that use the thinkpad_acpi driver. Features an interactive curve
 graph, manual/automatic/BIOS modes, temperature smoothing, a stall re-kick
 for low fan levels, and a thermal safety override (hardware watchdog + a
 critical-temperature full-speed override).
 .
 Developed and tested on the ThinkPad L490 (Ubuntu 24.04).
EOF

# --- maintainer scripts ---------------------------------------------------- #
cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
case "$1" in
  configure)
    # Migrate away from a previous manual (install.sh) deployment so systemd
    # doesn't keep running an /etc unit that points at /usr/local/bin.
    if [ -f /etc/systemd/system/thinkpad-fand.service ]; then
        systemctl disable --now thinkpad-fand.service 2>/dev/null || true
        rm -f /etc/systemd/system/thinkpad-fand.service
    fi
    rm -f /usr/local/bin/thinkpad-fand /usr/local/bin/thinkpad-fan-gui

    # Ensure thinkpad_acpi exposes writable fan control (experimental=1 is needed
    # on some models, harmless on the rest).
    MODCONF=/etc/modprobe.d/thinkpad_acpi.conf
    if ! grep -qs "fan_control=1" "$MODCONF" 2>/dev/null; then
        echo "options thinkpad_acpi fan_control=1 experimental=1" >> "$MODCONF"
    fi
    if [ ! -w /proc/acpi/ibm/fan ]; then
        modprobe -r thinkpad_acpi 2>/dev/null || true
        modprobe thinkpad_acpi 2>/dev/null || true
    fi

    # Config: created once, owned by the desktop user so the unprivileged GUI
    # can save it. (The root daemon validates everything it reads.)
    mkdir -p /etc/thinkpad-fan
    if [ ! -f /etc/thinkpad-fan/config.json ]; then
        cp /usr/share/thinkpad-fan-control/config.json /etc/thinkpad-fan/config.json
    fi
    DESKTOP_USER="${SUDO_USER:-}"
    [ -z "$DESKTOP_USER" ] && DESKTOP_USER="$(getent passwd 1000 | cut -d: -f1)"
    if [ -n "$DESKTOP_USER" ]; then
        chown -R "$DESKTOP_USER" /etc/thinkpad-fan
    else
        chmod -R a+rwX /etc/thinkpad-fan
    fi

    systemctl daemon-reload 2>/dev/null || true
    systemctl enable thinkpad-fand.service 2>/dev/null || true
    systemctl restart thinkpad-fand.service 2>/dev/null || true

    gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
    update-desktop-database /usr/share/applications 2>/dev/null || true
    ;;
esac
exit 0
EOF

cat > "$STAGE/DEBIAN/prerm" <<'EOF'
#!/bin/sh
set -e
case "$1" in
  remove|deconfigure)
    systemctl disable --now thinkpad-fand.service 2>/dev/null || true
    echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true   # hand fan back to firmware
    ;;
esac
exit 0
EOF

cat > "$STAGE/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = "purge" ]; then
    rm -rf /etc/thinkpad-fan
fi
systemctl daemon-reload 2>/dev/null || true
exit 0
EOF

chmod 0755 "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/prerm" "$STAGE/DEBIAN/postrm"

# --- build (fakeroot so payload is owned by root:root) --------------------- #
DEB="$BUILD/${PKG}_${VERSION}_all.deb"
fakeroot dpkg-deb --build "$STAGE" "$DEB"
echo
echo "Built: $DEB"
