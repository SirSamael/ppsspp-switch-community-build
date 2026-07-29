# PPSSPP Nintendo Switch Community Build

A community Nintendo Switch build of **PPSSPP v1.20.4** with additional Switch-specific improvements, compatibility fixes, and multiplayer debugging features.

This project is based on the original PPSSPP emulator and focuses on improving the Nintendo Switch experience through native **libnx support**, platform fixes, and testing improvements.

> This is an unofficial community build and is not affiliated with the official PPSSPP project.

---

## About This Project

PPSSPP is a PSP emulator that allows users to play PSP games on modern platforms.

This repository contains experimental Nintendo Switch-focused modifications designed to improve compatibility, stability, and development support for the Nintendo Switch platform.

The main goals of this project are:

- Improve Nintendo Switch compatibility
- Fix platform-specific issues
- Improve Adhoc multiplayer testing
- Provide a better development base for future Switch improvements

---

## Features

### Nintendo Switch Support

- Native Nintendo Switch build support using **libnx**
- CMake support for Nintendo Switch toolchain
- Switch-specific compatibility fixes
- Platform-specific system adjustments

### Graphics Improvements

- Nintendo Switch OpenGL compatibility fixes
- OpenGL function conflict handling
- Improved graphics backend compatibility

### Memory & System Improvements

- Switch-compatible memory handling
- libnx compatibility adjustments
- Platform-specific fixes for Switch environment

### Multiplayer Diagnostics

Additional tools for testing PSP Adhoc multiplayer:

- Network send timing diagnostics
- Packet delay detection
- Multiplayer troubleshooting logs
- Connection performance testing

---

## Based On

This project is based on:

- **PPSSPP v1.20.4**
- Original PPSSPP source code

Original project:

https://github.com/hrydgard/ppsspp

---

## Build Requirements

To build this project for Nintendo Switch, you need:

### Required Tools

- devkitPro
- devkitA64
- libnx
- Nintendo Switch portlibs
- CMake
- Ninja Build

Recommended environment:

- Windows + MSYS2
- Linux with devkitPro environment

---

The generated Nintendo Switch application can then be tested on compatible hardware.

---

## Current Development Status

- This project is currently experimental.
- Current testing areas:
- PSP game compatibility
- Nintendo Switch performance
- Adhoc multiplayer stability
- Graphics compatibility
- Memory management improvements
- Not all PSP games are guaranteed to work correctly.

---

## Changes From Upstream

This community build adds Nintendo Switch-focused changes:

- libnx compatibility improvements
- Switch-specific build fixes
- OpenGL compatibility adjustments
- Memory handling improvements
- Adhoc multiplayer debugging tools
- Network timing diagnostics

---

## Known Issues
- Some games may have compatibility problems.
- Multiplayer testing is still ongoing.
- Performance may vary depending on the game.
- Some features may require further Switch-specific optimization.
- Software keyboard opened automatically at startup
- Website and online-guide buttons crashed PPSSPP
- “JIT using IR” crashes
- NetLoader and nxlink instability
- Missing or invalid Homebrew Menu icon
- Green startup movies and cutscenes

---

## Submodule Patches
- Some Switch compatibility changes are stored as patch files.
- Location:
- patches/submodules:

Apply them after initializing submodules:
- git -C ext/aemu_postoffice apply ../../patches/submodules/aemu_postoffice-switch.patch

- git -C ext/glslang apply ../../patches/submodules/glslang-switch.patch

- git -C ext/lua apply ../../patches/submodules/lua-switch.patch

---

## Credits
- Original PPSSPP Development
- The original PPSSPP emulator is developed by:
- Henrik Rydgård (hrydgard) and contributors
- Original repository:
- https://github.com/hrydgard/ppsspp

---

## License

This project follows the licensing terms of the original PPSSPP project.

PPSSPP is licensed under the GPL-2.0-or-later license.

Please respect the original PPSSPP license and contributors.

---

## Nintendo Switch Community Build
- Nintendo Switch modifications, testing, and improvements:
- SirSamael

---

## Disclaimer
- This project is an unofficial community build.
- All trademarks and copyrights belong to their respective owners.
- Please support the original PPSSPP project.

---

## Building For Nintendo Switch

Example build configuration:

```bash
mkdir build
cd build

cmake .. -G Ninja \
-DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/cmake/Switch.cmake \
-DUSE_LIBNX=ON \
-DUSE_FFMPEG=OFF \
-DUSE_DISCORD=OFF \
-DZSTD_BUILD_SHARED=OFF \
-DZSTD_BUILD_STATIC=ON \
-DCMAKE_DISABLE_PRECOMPILE_HEADERS=ON

ninja

