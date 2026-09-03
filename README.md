# PPSSPP Switch Community Build

An unofficial Nintendo Switch community port of PPSSPP, based on PPSSPP v1.20.4.

This release focuses on stable game audio, correct video and cutscene playback,
Nintendo Switch compatibility, and a reproducible build process.

## Latest Release

Current experimental release:

    v0.7.0

Application metadata:

- Title: PPSSPP Switch Community Build
- Author: SirSamael
- Version: 0.7.0
- Installation path: `/switch/ppsspp/`

## Main Improvements

### Video and Cutscene Playback

This release uses a pinned FFmpeg compatibility backend built from:

    82049cca2e4c1516ed00a77b502a21f91b7843f4

The resulting decoder uses:

    libavcodec 57.24.102

This configuration fixed problems encountered with the newer system FFmpeg
package, including:

- Green or corrupted startup videos
- Corrupted in-game cutscenes
- Freezes during video playback
- Deterministic freezes at specific cutscene positions

FFmpeg is built into an isolated local prefix and does not replace the FFmpeg
libraries installed by devkitPro.

### Audio

Nintendo Switch audio changes include:

- 48,000 Hz default output
- Actual SDL device frequency passed to the PPSSPP mixer
- Stereo signed 16-bit output
- 2048-frame SDL audio buffer

These changes fixed:

- Missing game audio
- Buzzing audio
- Crackling audio
- Unstable audio playback

### Nintendo Switch Integration

- Nintendo Switch libnx support
- NXVK Vulkan graphics backend, selected by default
- OpenGL ES alternate renderer through Zink in the same NRO
- Switch-compatible memory and threading changes
- Homebrew Menu icon
- Embedded NACP application metadata
- Correct `/switch/ppsspp/` application data path
- Safe handling for unsupported external browser actions

### Reproducible Build System

The repository includes scripts for:

- Building the pinned FFmpeg compatibility libraries
- Applying required submodule patches
- Configuring PPSSPP with the tested CMake options
- Compiling the Nintendo Switch ELF
- Generating the NACP metadata
- Generating the final NRO
- Copying the generated PPSSPP assets
- Creating the SD-card release ZIP
- Generating a SHA-256 checksum

## Installation

Download the latest release ZIP from the GitHub Releases section.

Extract the ZIP directly to the root of the Nintendo Switch SD card.

The resulting structure must be:

    SD:/switch/ppsspp/PPSSPP.nro
    SD:/switch/ppsspp/assets/

After replacing an existing version, completely close and reopen the Homebrew
Menu so the updated application icon and metadata are refreshed.

Launch PPSSPP normally from the Homebrew Menu.

This NXVK build must be launched with title takeover, not from Album/applet
mode. NXVK requires the full application memory allocation. Hold `R` while
starting a retail title from the Homebrew Menu, then launch PPSSPP from that
title-takeover session.

Each release also provides a matching `-source.tar.gz` archive and checksum.
The source archive includes all submodules required to reproduce the binary,
including NXVK and FFmpeg.

## Required Runtime Settings

Use:

- CPU core: JIT
- Graphics backend: Vulkan (default on a fresh configuration)

OpenGL ES remains selectable in PPSSPP's graphics settings. In this release it
runs through Zink over NXVK, so both graphics choices use the same Switch
Vulkan driver. Zink is an alternate PPSSPP renderer, not an independent driver
fallback. Existing v0.6.5 configurations retain their saved OpenGL selection;
choose Vulkan in Graphics settings to migrate deliberately. The previous v0.6.5
GLES-only package remains the independent fallback for systems where this
experimental driver is unsuitable.

If both NXVK renderers fail before the menu appears, PPSSPP keeps the OpenGL ES
choice instead of cycling back to Vulkan. To retry automatic backend selection,
delete `PSP/SYSTEM/FailedGraphicsBackends.txt` from PPSSPP's memstick folder.

Do not use:

- JIT using IR

`JIT using IR` currently crashes every game in the tested compatibility set.
Regular JIT is required.

NXVK is experimental. Test both graphics backends before treating a game as
compatible with this release.

## Tested Games

The following games were confirmed to launch and run during final v0.6.0 testing:

- Danball Senki Boost
- God of War: Ghost of Sparta
- Grand Theft Auto: Liberty City Stories
- Tekken 6

Street Fighter Alpha 3 MAX was also tested during the earlier investigation.

Testing covered startup videos, cutscenes, game audio, gameplay, and general
stability where applicable.

This remains a limited compatibility test set. It does not guarantee that every
PSP game will work correctly.

## Performance Notes

- Performance varies by game.
- Grand Theft Auto: Liberty City Stories showed frequent frame drops.
- Tekken 6 showed occasional frame drops.
- Demanding games may require additional optimization.
- No universal performance guarantee is provided.

## Known Issues

- `JIT using IR` crashes currently tested games.
- NXVK Vulkan is experimental and may have game-specific issues.
- NetLoader and nxlink launching are not recommended.
- Some games may have performance or compatibility problems.
- Adhoc multiplayer compatibility may vary between games and network
  environments.

## Building from Source

Detailed instructions are available in:

    BUILD_SWITCH.md

Recommended automated build command:

    JOBS=2 ./scripts/build-switch-release.sh

The automated script generates:

    dist/v0.7.0/PPSSPP-Switch-Community-Build-v0.7.0.zip
    dist/v0.7.0/PPSSPP-Switch-Community-Build-v0.7.0.zip.sha256
    dist/v0.7.0/PPSSPP-Switch-Community-Build-v0.7.0-source.tar.gz
    dist/v0.7.0/PPSSPP-Switch-Community-Build-v0.7.0-source.tar.gz.sha256

The release archive contains:

    switch/ppsspp/PPSSPP.nro
    switch/ppsspp/assets/
    LICENSE.TXT
    THIRD_PARTY_NOTICES.md
    licenses/nxvk/
    BUILD-METADATA.txt

### Important FFmpeg Configuration

This build must use:

    -DUSE_FFMPEG=ON
    -DUSE_SYSTEM_FFMPEG=OFF
    -DFFMPEG_DIR=<isolated FFmpeg prefix>

Do not configure this release with:

    -DUSE_SYSTEM_FFMPEG=ON

See `BUILD_SWITCH.md` for the complete toolchain, FFmpeg, CMake, compilation, and
packaging instructions.

## Repository Structure

Important release-specific files:

    BUILD_SWITCH.md
    CHANGELOG.md
    icons/PPSSPP-icon.jpg
    patches/submodules/
    scripts/build-switch-ffmpeg57.sh
    scripts/build-switch-release.sh

Required submodule patches:

    patches/submodules/aemu-postoffice-switch.patch
    patches/submodules/glslang-switch.patch
    patches/submodules/lua-switch.patch

## Development and Testing

Nintendo Switch adaptation, compilation, device testing, and release maintenance:

    SirSamael

ChatGPT was used for research, debugging guidance, build investigation,
documentation, and release preparation.

## Upstream Project

PPSSPP is an open-source PSP emulator created and maintained by the official
PPSSPP developers and contributors.

This repository is an unofficial Nintendo Switch community build and is not an
official PPSSPP release.

## License

PPSSPP is distributed under the GNU General Public License version 2 or later.

See:

    LICENSE.TXT

Third-party components retain their respective licenses and copyright notices.
