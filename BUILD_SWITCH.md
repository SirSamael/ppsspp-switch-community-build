# PPSSPP Switch Community Build v0.5.0 Beta

Build instructions for the Nintendo Switch community build based on PPSSPP v1.20.4.

## Requirements

- devkitPro
- devkitA64
- libnx and switch-dev
- switch-sdl2
- switch-ffmpeg
- CMake, Ninja and Git

## 1. Initialise Submodules

    git submodule update --init --recursive

## 2. Apply Switch Submodule Patches

    git -C ext/aemu_postoffice apply --unidiff-zero ../../patches/submodules/aemu-postoffice-switch.patch
    git -C ext/glslang apply --unidiff-zero ../../patches/submodules/glslang-switch.patch
    git -C ext/lua apply --unidiff-zero ../../patches/submodules/lua-switch.patch

## 3. Create the Build Directory

    mkdir build
    cd build

## 4. Configure CMake

Run this as one command from inside the build directory:

    cmake .. -G Ninja -DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/cmake/Switch.cmake -DUSE_LIBNX=ON -DUSING_EGL=ON -DUSING_GLES2=ON -DUSING_FBDEV=ON -DUSE_NO_MMAP=ON -DUSE_MINIUPNPC=OFF -DUSE_SYSTEM_LIBSDL2=ON -DUSE_FFMPEG=ON -DUSE_SYSTEM_FFMPEG=ON -DUSE_DISCORD=OFF -DUSE_SYSTEM_ZSTD=OFF -DARMIPS_USE_STD_FILESYSTEM=ON -DCMAKE_DISABLE_PRECOMPILE_HEADERS=ON -DCMAKE_POLICY_VERSION_MINIMUM=3.5

## 5. Compile

    cmake --build . -j2

## 6. Generate the NRO

Run this from inside the build directory:

    /opt/devkitpro/tools/bin/elf2nro PPSSPPSDL.elf PPSSPP.nro --icon=PPSSPP-icon.jpg --nacp=PPSSPP.nacp

## 7. SD Card Installation

The final SD card structure must be:

    SD:/switch/ppsspp/PPSSPP.nro
    SD:/switch/ppsspp/assets/

Copy the complete source assets folder together with PPSSPP.nro.
Launch PPSSPP normally through the Homebrew Menu.
NetLoader and nxlink are not recommended.

## Recommended Runtime Settings

- CPU core: JIT
- Graphics backend: OpenGL ES
- Do not use JIT using IR
- Vulkan is not supported

## Tested Game

The main testing for this release was performed using Monster Hunter Portable 3rd (MHP3rd).
Compatibility and performance may differ with other PSP games.

## Audio Configuration

- 48,000 Hz output
- Stereo signed 16-bit audio
- 2048-sample SDL audio buffer

These settings fixed missing, buzzing and crackling audio during testing.

## Development Credit

This build was developed through a vibe-coding workflow using ChatGPT for research, debugging guidance, patch development, build troubleshooting, testing assistance and documentation.

All source changes were reviewed, compiled and tested by SirSamael.
