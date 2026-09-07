# PPSSPP Switch Community Build

An unofficial Nintendo Switch community port of PPSSPP, based on PPSSPP v1.20.4.

The project provides a stable OpenGL build and an experimental NXVK Vulkan
preview, with working game audio, video playback, Nintendo Switch integration,
and a reproducible build process.

## Releases

### Stable OpenGL release — v0.6.5

The recommended stable build continues to use OpenGL ES.

[Download v0.6.5](https://github.com/SirSamael/ppsspp-switch-community-build/releases/tag/v0.6.5)

### Experimental Vulkan preview — v0.7.0

v0.7.0 introduces the NXVK Vulkan renderer through
[PR #17](https://github.com/SirSamael/ppsspp-switch-community-build/pull/17).
It has been verified on real Nintendo Switch hardware with working gameplay,
audio, touch input, controller input, clean presentation, and normal exit to the
HOME Menu.

[Download v0.7.0](https://github.com/SirSamael/ppsspp-switch-community-build/releases/tag/v0.7.0)

- Source branch: [`integration/pr17-vulkan`](https://github.com/SirSamael/ppsspp-switch-community-build/tree/integration/pr17-vulkan)
- ZIP SHA-256: `092bea8f18ef3a845bbda0d259fb2fd65b52132f390ec88705e213ead90c472c`
- Status: Experimental pre-release

Application metadata:

- Title: PPSSPP Switch Community Build
- Author: SirSamael
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
- OpenGL ES graphics backend
- Experimental NXVK Vulkan renderer in v0.7.0
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

Launch v0.6.5 normally from the Homebrew Menu. For the v0.7.0 Vulkan preview,
use full-memory title takeover.

## Required Runtime Settings

### v0.6.5 stable build

- CPU core: JIT
- Graphics backend: OpenGL ES

Vulkan is not included in v0.6.5, and `JIT using IR` is not recommended for
that stable build.

### v0.7.0 Vulkan preview

- CPU core: JIT
- Graphics backend: Vulkan
- Launch method: Full-memory title takeover

OpenGL remains available in v0.7.0. Vulkan is experimental and is not yet
consistently faster than OpenGL.

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

- Vulkan support in v0.7.0 is experimental.
- Vulkan performance is game-dependent and is not yet consistently faster than OpenGL.
- High rendering resolutions can substantially reduce performance.
- `JIT using IR` is not recommended for the v0.6.5 stable build.
- NetLoader and nxlink launching are not recommended.
- Some games may have performance or compatibility problems.
- Adhoc multiplayer compatibility may vary between games and network environments.

## Building from Source

The instructions below describe the stable `release-v0.6.0` source branch.
The v0.7.0 Vulkan source and release scripts are maintained on
[`integration/pr17-vulkan`](https://github.com/SirSamael/ppsspp-switch-community-build/tree/integration/pr17-vulkan).

Detailed instructions are available in:

    BUILD_SWITCH.md

Recommended automated build command:

    JOBS=2 ./scripts/build-switch-release.sh

The automated script generates:

    dist/v0.6.0/PPSSPP-Switch-Community-Build-v0.6.0.zip
    dist/v0.6.0/PPSSPP-Switch-Community-Build-v0.6.0.zip.sha256

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

NXVK Vulkan integration and contribution:

    JohsonChou

Special thanks to [@JohsonChou](https://github.com/JohsonChou) for contributing
the v0.7.0 Vulkan foundation through PR #17.

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
