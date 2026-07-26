# Building PPSSPP Nintendo Switch Community Build

This guide explains how to compile the Nintendo Switch version of this PPSSPP community build.

---

# Requirements

## Development Environment

You need:

- devkitPro
- devkitA64
- libnx
- Switch portlibs
- CMake
- Ninja Build
- Git

Recommended:

- Windows 10/11 with MSYS2
- Linux with devkitPro environment

---

# Tested Environment

This build guide was tested with:

- Windows 11
- MSYS2
- devkitPro
- devkitA64
- libnx
- CMake
- Ninja Build

---

# Installing devkitPro

Install devkitPro from:

https://devkitpro.org/

After installation, make sure these packages are installed:

```
devkitA64
libnx
switch-dev
switch-cmake
switch-tools
```

---

# Clone Repository

Clone the repository:

```bash
git clone https://github.com/SirSamael/ppsspp-switch-community-build.git

cd ppsspp-switch-community-build
```

Initialize submodules:

```bash
git submodule update --init --recursive
```

---

# Applying Switch Submodule Patches

This project includes some Switch-specific submodule modifications.

Apply patches:

```bash
git -C ext/aemu_postoffice apply ../../patches/submodules/aemu_postoffice-switch.patch

git -C ext/glslang apply ../../patches/submodules/glslang-switch.patch

git -C ext/lua apply ../../patches/submodules/lua-switch.patch
```

---

# Configure Build

Create build folder:

```bash
mkdir build

cd build
```

Run CMake:

```bash
cmake .. -G Ninja \
-DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/cmake/Switch.cmake \
-DUSE_LIBNX=ON \
-DUSE_FFMPEG=OFF \
-DUSE_DISCORD=OFF \
-DZSTD_BUILD_SHARED=OFF \
-DZSTD_BUILD_STATIC=ON \
-DCMAKE_DISABLE_PRECOMPILE_HEADERS=ON
```

---

# Compile

Build the project:

```bash
ninja
```

After successful compilation, the generated Nintendo Switch application can be tested on compatible hardware.

---

# Testing

Copy the generated `.nro` file to your Nintendo Switch SD card:

```
/switch/PPSSPP/
```

Launch it using Homebrew Menu.

---

# Troubleshooting

## Build Errors

Make sure:

- devkitPro environment variables are correct
- libnx is updated
- all submodules are initialized
- patches are applied correctly

## Performance Issues

Performance may vary depending on:

- PSP game
- graphics settings
- emulator configuration

---

# Development Status

This is an experimental community build.

Testing focuses on:

- Game compatibility
- Multiplayer stability
- Graphics compatibility
- Performance improvements

Contributions and testing reports are welcome.
