# PPSSPP Switch Community Build v0.7.0

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
- switch-libexpat (recommended; the release script builds NXVK's pinned
  vendored Expat fallback when this portlib is unavailable)
- CMake
- Ninja
- Git
- Python 3
- GNU Make
- pkg-config
- Docker or Podman, capable of building and running the NXVK container

The devkitPro `switch-ffmpeg` package may remain installed, but it is not linked
into this build.

## Clone and Initialize

Clone the repository and select the release branch:

    git clone --recursive https://github.com/SirSamael/ppsspp-switch-community-build.git
    cd ppsspp-switch-community-build
    git switch feature/switch-nxvk-vulkan

For an existing clone:

    git submodule sync --recursive
    git submodule update --init --recursive

## Recommended Automated Build

The automated script performs the complete process:

1. Initializes all Git submodules.
2. Verifies the pinned FFmpeg revision.
3. Applies the required Switch submodule patches.
4. Builds FFmpeg 57 into an isolated local prefix.
5. Builds pinned NXVK plus the Zink OpenGL ES alternate renderer into a local prefix.
6. Configures and compiles PPSSPP.
7. Generates the NACP metadata and NRO.
8. Copies the generated 185-file asset set.
9. Creates the SD-card ZIP, complete corresponding source archive, and SHA-256
   checksums.

Run from the repository root:

    JOBS=2 ./scripts/build-switch-release.sh

Generated files:

    dist/v0.7.0/PPSSPP-Switch-Community-Build-v0.7.0.zip
    dist/v0.7.0/PPSSPP-Switch-Community-Build-v0.7.0.zip.sha256
    dist/v0.7.0/PPSSPP-Switch-Community-Build-v0.7.0-source.tar.gz
    dist/v0.7.0/PPSSPP-Switch-Community-Build-v0.7.0-source.tar.gz.sha256

The ZIP archive contains:

    switch/ppsspp/PPSSPP.nro
    switch/ppsspp/assets/
    LICENSE.TXT
    THIRD_PARTY_NOTICES.md
    licenses/nxvk/
    BUILD-METADATA.txt

Release builds must start from committed top-level source. This ensures the
generated source archive is the exact source corresponding to the binary.

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

### 4. Build NXVK and Zink

The pinned `ext/nxvk` submodule builds Vulkan and the OpenGL ES Zink alternate renderer
inside its container. The release script stages its output automatically. For a
manual build, use the same host-user wrapper and derived image as the release
script:

    make -C ext/nxvk image CONTAINER="$PWD/scripts/docker-as-host-user.sh"
    DOCKER_BIN=docker scripts/docker-as-host-user.sh \
      build -t nxvk-ppsspp -f scripts/nxvk.Dockerfile .
    make -C ext/nxvk gl \
      CONTAINER="$PWD/scripts/docker-as-host-user.sh" \
      IMAGE=nxvk-ppsspp \
      DEVKITPRO=/opt/devkitpro

Then stage its libraries and Vulkan headers:

    rm -rf build-switch-nxvk-prefix
    mkdir -p build-switch-nxvk-prefix/lib build-switch-nxvk-prefix/include
    cp -a ext/nxvk/switch/build/pkg/lib/. build-switch-nxvk-prefix/lib/
    cp -a ext/nxvk/include/vulkan ext/nxvk/include/vk_video \
      build-switch-nxvk-prefix/include/

The staged prefix must retain `lib/pkgconfig/nxvk-gl.pc`; CMake verifies this
NXVK portlib manifest is present. The release script also verifies the pinned
NXVK commit before building.

### 5. Configure PPSSPP

Run from the repository root:

    cmake \
      -S . \
      -B build-switch-v0.7.0 \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/cmake/Switch.cmake \
      -DCMAKE_PREFIX_PATH=/opt/devkitpro/portlibs/switch \
      -DUSE_LIBNX=ON \
      -DSWITCH_USE_NXVK=ON \
      -DNXVK_PREFIX="$PWD/build-switch-nxvk-prefix" \
      -DPPSSPP_GIT_VERSION_OVERRIDE=v0.7.0 \
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

### 6. Compile PPSSPP

    cmake --build build-switch-v0.7.0 --parallel 2

Expected executable:

    build-switch-v0.7.0/PPSSPPSDL.elf

Expected generated assets:

    build-switch-v0.7.0/assets/

### 7. Generate Homebrew Metadata

    /opt/devkitpro/tools/bin/nacptool --create \
      "PPSSPP Switch Community Build" \
      "SirSamael" \
      "0.7.0" \
      build-switch-v0.7.0/PPSSPP.nacp

### 8. Generate the NRO

    /opt/devkitpro/tools/bin/elf2nro \
      build-switch-v0.7.0/PPSSPPSDL.elf \
      build-switch-v0.7.0/PPSSPP.nro \
      --icon=icons/PPSSPP-icon.jpg \
      --nacp=build-switch-v0.7.0/PPSSPP.nacp

## SD Card Installation

Extract or copy the release package so the final SD-card layout is:

    SD:/switch/ppsspp/PPSSPP.nro
    SD:/switch/ppsspp/assets/

Completely close and reopen the Homebrew Menu after replacing the application so
the updated icon and metadata are refreshed.

Launch PPSSPP normally through the Homebrew Menu.

This NXVK release requires title takeover and must not be started through
Album/applet mode. Hold `R` while launching a retail title from the Homebrew
Menu, then start PPSSPP in that title-takeover session. NXVK requires the full
application memory allocation.

Choosing Exit closes the title-takeover session and returns to the HOME Menu.
This intentionally avoids returning to Sphaira because its current restore path
can crash after an SDL audio homebrew application exits.

NetLoader and nxlink launching are not recommended for this release.

## Runtime Configuration

Use:

- CPU core: JIT
- Graphics backend: Vulkan (default on a fresh configuration)

Do not use:

- JIT using IR

`JIT using IR` crashed every game in the current test set. Regular JIT is the
required CPU core for this release. OpenGL ES remains selectable as a Zink
alternate renderer in the same NRO. Both choices share the NXVK driver, so this
is not an independent fallback. Existing v0.6.5 configurations retain OpenGL
until Vulkan is selected in settings. If both choices fail before the menu
appears, delete `PSP/SYSTEM/FailedGraphicsBackends.txt` from PPSSPP's memstick
folder before retrying.

## Audio Configuration

Nintendo Switch audio changes used by this build:

- 48,000 Hz default output
- Actual output frequency returned by SDL passed to the mixer
- Stereo signed 16-bit audio
- 2048-frame SDL audio buffer

These changes fixed missing, buzzing and crackling audio encountered during
testing.

## Tested Games

The following games were confirmed to launch and run during v0.6.0 testing:

- Danball Senki Boost
- God of War: Ghost of Sparta
- Grand Theft Auto: Liberty City Stories
- Tekken 6

Earlier investigation also tested Street Fighter Alpha 3 MAX.

This is a limited compatibility test set and is not a guarantee that every PSP
game will work correctly.

## NXVK Release Validation

Before publishing an NXVK release, verify each intended game in Vulkan and, at
least once, in the Zink OpenGL ES alternate renderer. Cover menu, gameplay,
return-to-menu, and game exit in both handheld and docked modes. Also verify
title-takeover launch, HOME suspend/resume, dock/undock while running, backend
switching followed by restart, and recovery after an intentionally failed
backend selection.

## Performance Notes

- Native Vulkan uses NXVK's block-linear zero-copy presentation path. A local
  NXVK patch makes graphics completion fences wait for pending rendering and
  flush its caches before the Switch display scans the image.
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
