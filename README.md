# PPSSPP Switch Community Build

An unofficial Nintendo Switch community port of PPSSPP, based on PPSSPP v1.20.4.

This release focuses on stable game audio, correct video and cutscene playback,
Nintendo Switch compatibility, and a reproducible build process.

## Latest Release

Current release:

    v0.6.5

Application metadata:

- Title: PPSSPP
- Author: PPSSPP Team
- Version: 0.6.5
- Installation path: `/switch/ppsspp/`

## Main Improvements

### Version 0.6.5 Fixes and Performance Work

- Added hardware-tested ARM64 JIT cache-pointer preservation fixes.
- Fixed the ARM64 IR/JIT cache-pointer crash path.
- Added parallel software depth rasterization using non-overlapping,
  four-pixel-aligned worker tiles.
- Added Switch process-core detection for worker scheduling.
- Added Switch readable memory aliases for affected texture and CLUT reads.
- Fixed video swizzle-buffer ownership and initialization.
- Fixed negative render-target offsets in the OpenGL ES shader path.
- Fixed SDL trigger mapping and right-stick threshold behavior.
- Improved native Switch keyboard and multilingual input support.
- Added fallback fonts for CJK, Arabic, Hebrew, Thai and Lao.
- Retains the validated FFmpeg and audio fixes from Version 0.6.0.


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
- OpenGL ES graphics backend
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

## Required Runtime Settings

Recommended:

- CPU core: JIT
- Graphics backend: OpenGL ES

Version 0.6.5 includes the hardware-tested ARM64 IR/JIT cache-pointer
correction. Regular JIT remains recommended for the widest compatibility.

Vulkan is not supported by this community build.

## Tested Games

The following games were confirmed to launch and run during final v0.6.5 testing:

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

- Vulkan is not supported.
- Regular JIT remains recommended even though the tested ARM64 IR/JIT crash
  path was corrected in Version 0.6.5.
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

    dist/v0.6.5/PPSSPP-Switch-0.6.5.zip
    dist/v0.6.5/PPSSPP-Switch-0.6.5.zip.sha256

The release archive contains:

    switch/ppsspp/PPSSPP.nro
    switch/ppsspp/assets/

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
