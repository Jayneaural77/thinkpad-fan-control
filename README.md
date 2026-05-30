# ThinkPad Fan Control

A small fan-control utility for ThinkPad laptops on Linux (built and tested for a
**ThinkPad L490 on Ubuntu 24.04**). It gives you what the firmware/GNOME profiles
don't: **automatic temperature-based control with 8 speed levels** plus a GUI for
manual override.

## What you get

- **`thinkpad-fand`** — a small root daemon (systemd service) that is the *only*
  writer to `/proc/acpi/ibm/fan`. It runs the automatic temperature curve and
  enforces safety.
- **`thinkpad-fan-gui`** — a Tkinter desktop app (runs as your normal user) to
  watch temps/RPM and choose the mode/level.

The two talk only through a JSON config file (`/etc/thinkpad-fan/config.json`),
so the GUI never needs root — clean and Wayland-friendly.

## Modes

| Mode | Behaviour |
|------|-----------|
| **Automatic** | Picks fan level 0–7 from CPU temperature using an editable curve, with hysteresis so it doesn't oscillate. Edit it on an **interactive graph** (Y = temperature, X = fan speed %) by dragging points, or with the numeric boxes / presets — the two stay in sync. |
| **Manual** | Holds a fixed level you choose (slider 0–7, plus *Full speed* / *Disengaged*). |
| **BIOS** | Hands control back to the firmware (`level auto`). |

### Other GUI features

- **Curve graph** — drag the dots to set the temperature at which each fan speed
  turns on; points are kept monotonic automatically.
- **Temperature smoothing** — the curve reacts to an averaged temperature
  (default: 12 s) so brief CPU turbo spikes don't surge the fan on and off. The
  safety override still watches the raw temperature and reacts instantly.
- **Stall re-kick** — on some ThinkPads the lowest fan levels (≈1–3) can't keep
  the fan spinning; it spins up then stalls to 0 RPM. When enabled, the daemon
  re-issues a stalled level periodically to pulse some airflow. Levels that do
  sustain (RPM > 0) are never re-kicked, so higher speeds stay perfectly smooth.
- **Launch at login** — a checkbox in *Settings* adds/removes an XDG autostart
  entry so the control panel opens when you log in. (The background fan service
  starts on boot regardless.)
- **App icon** — installed for the menu/dock launcher and the window.

## Safety (built in, cannot be disabled)

- **Critical-temperature override** — above your configured limit (default 87 °C,
  hard cap 90 °C) the fan is forced to full speed regardless of mode. This is what
  makes the user-editable config safe.
- **Hardware watchdog** — re-armed every loop. If the daemon ever crashes, the
  firmware resumes automatic cooling within ~10 s. The fan can't get stuck off.
- **Graceful stop** — stopping the service restores firmware `auto`.
- The daemon validates and clamps everything it reads from the config file.

## Install

```bash
cd ~/Desktop/thinkpad-fan-control
chmod +x install.sh uninstall.sh        # if not already
sudo ./install.sh
```

Then open **“ThinkPad Fan Control”** from your applications menu, or run
`thinkpad-fan-gui`.

## Useful commands

```bash
systemctl status thinkpad-fand      # service state
journalctl -u thinkpad-fand -f      # live log of what level it's setting
thinkpad-fand --dry-run             # (as root) print decisions without touching the fan
```

## Uninstall

```bash
sudo ./uninstall.sh
```

## Notes

- *Disengaged* removes the fan's speed cap for maximum airflow — meant for short
  bursts, not sustained use.
- The default curve is quiet at idle (fan off below 50 °C) and ramps up smoothly.
  Tune it in the GUI (presets: Quiet / Balanced / Cool, or set per-level
  thresholds), then press **Apply**.
