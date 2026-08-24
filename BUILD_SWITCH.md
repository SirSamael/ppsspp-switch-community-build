# PPSSPP Switch Community Build v0.6.5

Build instructions for the Nintendo Switch community build based on PPSSPP v1.20.4.

## Important FFmpeg Requirement

This release must use the isolated legacy FFmpeg libraries built from the pinned
PPSSPP FFmpeg submodule revision:

    82049cca2e4c1516ed00a77b502a21f91b7843f4

The resulting decoder reports FFmpeg `libavcodec 57.24.102`.

Do not build this release with the current devkitPro `switch-ffmpeg` package.
Testing found that the newer system FFmpeg configuration caused corrupted or
green video playback and deterministic freezes during some PSP cutscenes.

The PPSSPP build must therefore use:

    -DUSE_FFMPEG=ON
    -DUSE_SYSTEM_FFMPEG=OFF
    -DFFMPEG_DIR=<isolated FFmpeg prefix>

## Requirements

- MSYS2 or another compatible Unix-style shell
- devkitPro
- devkitA64
- libnx and switch-dev
- switch-sdl2
- switch-libpng
- CMake
- Ninja
- Git
- Python 3
- GNU Make
- pkg-config

The devkitPro `switch-ffmpeg` package may remain installed, but it is not linked
into this build.

## Clone and Initialize

Clone the repository and select the release branch:

    git clone --recursive https://github.com/SirSamael/ppsspp-switch-community-build.git
    cd ppsspp-switch-community-build
    git switch release-v0.6.5

For an existing clone:

    git submodule sync --recursive
    git submodule update --init --recursive

## Recommended Automated Build

The automated script performs the complete process:

1. Initializes all Git submodules.
2. Verifies the pinned FFmpeg revision.
3. Applies the required Switch submodule patches.
4. Builds FFmpeg 57 into an isolated local prefix.
5. Configures and compiles PPSSPP.
6. Generates the NACP metadata and NRO.
7. Copies the generated 190-file asset set.
8. Creates the SD-card ZIP and SHA-256 checksum.

Run from the repository root:

    JOBS=2 ./scripts/build-switch-release.sh

Generated files:

    dist/v0.6.5/PPSSPP-Switch-0.6.5.zip
    dist/v0.6.5/PPSSPP-Switch-0.6.5.zip.sha256

The ZIP archive contains:

    switch/ppsspp/PPSSPP.nro
    switch/ppsspp/assets/

## Manual Build

### 1. Initialize Submodules

    git submodule sync --recursive
    git submodule update --init --recursive

### 2. Apply Switch Submodule Patches

Run these commands from the repository root:

    git -C ext/aemu_postoffice apply ../../patches/submodules/aemu-postoffice-switch.patch
    git -C ext/glslang apply ../../patches/submodules/glslang-switch.patch
    git -C ext/lua apply ../../patches/submodules/lua-switch.patch

Before applying a patch again, check whether it is already applied.

### 3. Build the Isolated FFmpeg Libraries

    JOBS=2 ./scripts/build-switch-ffmpeg57.sh

The script creates:

    build-switch-ffmpeg57/
    build-switch-ffmpeg57-prefix/

Required static libraries:

    build-switch-ffmpeg57-prefix/lib/libavcodec.a
    build-switch-ffmpeg57-prefix/lib/libavformat.a
    build-switch-ffmpeg57-prefix/lib/libavutil.a
    build-switch-ffmpeg57-prefix/lib/libswresample.a
    build-switch-ffmpeg57-prefix/lib/libswscale.a

The script does not overwrite the libraries installed under devkitPro.

### 4. Configure PPSSPP

Run from the repository root:

    cmake \
      -S . \
      -B build-switch-v0.6.5 \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/cmake/Switch.cmake \
      -DUSE_LIBNX=ON \
      -DUSING_EGL=ON \
      -DUSING_GLES2=ON \
      -DUSING_FBDEV=ON \
      -DUSE_NO_MMAP=ON \
      -DUSE_MINIUPNPC=OFF \
      -DUSE_SYSTEM_MINIUPNPC=OFF \
      -DUSE_SYSTEM_LIBPNG=ON \
      -DUSE_SYSTEM_LIBSDL2=ON \
      -DUSE_FFMPEG=ON \
      -DUSE_SYSTEM_FFMPEG=OFF \
      -DFFMPEG_DIR="$PWD/build-switch-ffmpeg57-prefix" \
      -DUSE_DISCORD=OFF \
      -DUSE_SYSTEM_ZSTD=OFF \
      -DARMIPS_USE_STD_FILESYSTEM=ON \
      -DCMAKE_DISABLE_PRECOMPILE_HEADERS=ON \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5

### 5. Compile PPSSPP

    cmake --build build-switch-v0.6.5 --parallel 2

Expected executable:

    build-switch-v0.6.5/PPSSPPSDL.elf

Expected generated assets:

    build-switch-v0.6.5/assets/

### 6. Generate Homebrew Metadata

    /opt/devkitpro/tools/bin/nacptool --create \
      "PPSSPP" \
      "PPSSPP Team" \
      "0.6.5" \
      build-switch-v0.6.5/PPSSPP.nacp

### 7. Generate the NRO

    /opt/devkitpro/tools/bin/elf2nro \
      build-switch-v0.6.5/PPSSPPSDL.elf \
      build-switch-v0.6.5/PPSSPP.nro \
      --icon=icons/PPSSPP-icon.jpg \
      --nacp=build-switch-v0.6.5/PPSSPP.nacp

## SD Card Installation

Extract or copy the release package so the final SD-card layout is:

    SD:/switch/ppsspp/PPSSPP.nro
    SD:/switch/ppsspp/assets/

Completely close and reopen the Homebrew Menu after replacing the application so
the updated icon and metadata are refreshed.

Launch PPSSPP normally through the Homebrew Menu.

NetLoader and nxlink launching are not recommended for this release.

## Runtime Configuration

Recommended:

- CPU core: JIT
- Graphics backend: OpenGL ES

Version 0.6.5 includes the hardware-tested ARM64 IR/JIT cache-pointer
correction. Regular JIT remains recommended for the widest compatibility.

Vulkan is not supported by this community build.

## Audio Configuration

Nintendo Switch audio changes used by this build:

- 48,000 Hz default output
- Actual output frequency returned by SDL passed to the mixer
- Stereo signed 16-bit audio
- 2048-frame SDL audio buffer

These changes fixed missing, buzzing and crackling audio encountered during
testing.

## Tested Games

The following games were confirmed to launch and run during v0.6.5 testing:

- Danball Senki Boost
- God of War: Ghost of Sparta
- Grand Theft Auto: Liberty City Stories
- Tekken 6

Earlier investigation also tested Street Fighter Alpha 3 MAX.

This is a limited compatibility test set and is not a guarantee that every PSP
game will work correctly.

## Performance Notes

- Overall performance remained comparable to the previously tested Nintendo
  Switch build.
- Grand Theft Auto: Liberty City Stories showed frequent frame drops.
- Tekken 6 showed occasional frame drops.
- Performance varies by game.

## Development Credit

Nintendo Switch adaptation, compilation, device testing and release maintenance:

    SirSamael

ChatGPT was used for research, debugging guidance, build investigation,
documentation and release preparation.

PPSSPP and its bundled third-party components remain the work of their respective
upstream authors and contributors.
