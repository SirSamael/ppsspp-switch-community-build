# PPSSPP Nintendo Switch Community Build

A community Nintendo Switch build of **PPSSPP v1.20.4** with additional Switch-specific improvements, compatibility fixes, and multiplayer debugging features.

This project is based on the original PPSSPP emulator and focuses on improving the Nintendo Switch experience through native **libnx** support and platform-specific optimizations.

---

## About This Project

PPSSPP is a PSP emulator that allows users to play PSP games on modern platforms.

This repository contains experimental Nintendo Switch-focused modifications, including:

- Nintendo Switch `libnx` build support
- Switch compatibility improvements
- OpenGL-related fixes
- Memory allocation improvements
- Network diagnostics for Adhoc multiplayer testing
- Platform-specific fixes required for Switch compilation

This is a community-driven project and is not an official PPSSPP release.

---

## Features

### Nintendo Switch Support

- Native Nintendo Switch build using devkitPro/libnx
- CMake support for Switch toolchain
- Switch-specific platform fixes
- Improved compatibility with Nintendo Switch libraries

### Graphics Improvements

- Nintendo Switch OpenGL compatibility fixes
- Function name conflict handling
- Improved GL stub compatibility for Switch environment

### Memory & System Improvements

- Switch-compatible virtual memory handling
- libnx compatibility adjustments
- Platform-specific system fixes

### Multiplayer Diagnostics

Additional network logging tools for testing PSP Adhoc multiplayer:

- Send timing diagnostics
- Network delay detection
- Packet timing analysis
- Multiplayer troubleshooting support

---

## Based On

This project is based on:

- PPSSPP v1.20.4
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
- Switch portlibs
- CMake
- Ninja Build

Recommended environment:

- Windows + MSYS2
- Linux with devkitPro environment

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
