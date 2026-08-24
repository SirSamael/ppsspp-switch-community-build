# v0.6.5

Nintendo Switch community release based on PPSSPP v1.20.4.

## ARM64 JIT and Memory Corrections

- Added cache-pointer preservation fixes to ARM64 FPU and VFPU load/store
  compilation paths.
- Corrected the tested ARM64 IR/JIT cache-pointer crash path.
- Added Switch readable source-alias tracking for affected memory mappings.
- Corrected affected main-RAM texture and CLUT reads.
- Improved backing-memory initialization and alias lifecycle handling.

## Software Depth Performance

- Added parallel software depth rasterization.
- Uses non-overlapping, four-pixel-aligned vertical worker tiles.
- Prevents worker threads from racing on shared raster statistics.
- Uses the Nintendo Switch process core mask for worker scheduling.
- Retains serial clipping and draw ordering.

## Input and Interface

- Corrected SDL trigger translation and default trigger mapping.
- Restored right-stick diagonal threshold handling.
- Improved native Switch software-keyboard availability.
- Enabled multilingual Switch keyboard input.
- Added fallback fonts for CJK, Arabic, Hebrew, Thai and Lao.

## Graphics, Video and Compatibility

- Fixed video swizzle-buffer initialization and ownership.
- Corrected negative render-target offsets in the OpenGL ES shader path.
- Retains the validated FFmpeg 57 video and 48 kHz audio configuration.
- Excludes DIAG13 timing overlays and diagnostic instrumentation.

## Packaging

- Application name: `PPSSPP`
- Author: `PPSSPP Team`
- Version: `0.6.5`
- Installation path: `/switch/ppsspp/`
- Includes the tested PPSSPP Homebrew Menu icon.
- Includes 190 generated runtime asset files.
- Release archive: `PPSSPP-Switch-0.6.5.zip`

## Testing

Version 0.6.5 was built and tested successfully on Nintendo Switch hardware.
Regular JIT remains recommended for the widest compatibility.

## Known Limitations

- Vulkan is not supported.
- NetLoader and nxlink launching are not recommended.
- Compatibility and performance vary by game.

## Development

Nintendo Switch adaptation, compilation, device testing and release maintenance
were performed by SirSamael.

ChatGPT was used for research, debugging guidance, build investigation,
documentation and release preparation.

---

# v0.6.0

Stable Nintendo Switch community release based on PPSSPP v1.20.4.

## Video Playback and FFmpeg

- Replaced the incompatible devkitPro system FFmpeg configuration with an
  isolated legacy FFmpeg build.
- Pinned the PPSSPP FFmpeg submodule to commit
  `82049cca2e4c1516ed00a77b502a21f91b7843f4`.
- Uses `libavcodec 57.24.102` and the matching legacy FFmpeg libraries.
- Fixed corrupted or green startup videos and cutscenes.
- Fixed deterministic freezes encountered during video playback.
- Added a reproducible FFmpeg 57 build script that installs into a local prefix
  without overwriting devkitPro system libraries.

## Audio

- Uses a 48,000 Hz default Nintendo Switch audio output rate.
- Passes the actual SDL output frequency to the PPSSPP audio mixer.
- Uses a 2048-frame SDL audio buffer.
- Fixed missing game audio.
- Fixed buzzing and crackling encountered during testing.

## Build and Packaging

- Added an automated Nintendo Switch build and release packaging script.
- Added verification for the required FFmpeg submodule revision.
- Added automatic application and validation of the three Switch submodule
  patches.
- Added automatic NACP and NRO generation.
- Added the tested 256×256 Homebrew Menu icon.
- Added application metadata:
  - Title: `PPSSPP Switch Community Build`
  - Author: `SirSamael`
  - Version: `0.6.0`
- Added automatic creation of the SD-card ZIP archive and SHA-256 checksum.
- Release packages use the required `switch/ppsspp/` directory structure.
- Updated all build instructions to use isolated FFmpeg instead of
  `USE_SYSTEM_FFMPEG=ON`.

## Runtime Configuration

- Regular JIT is the required CPU core for this release.
- OpenGL ES is the supported graphics backend.
- `JIT using IR` crashed every game in the current test set.
- Vulkan is not supported by this community build.

## Confirmed Test Results

The following games were confirmed to launch and run:

- Danball Senki Boost
- God of War: Ghost of Sparta
- Grand Theft Auto: Liberty City Stories
- Tekken 6

Street Fighter Alpha 3 MAX was also tested during the earlier investigation.

## Performance

- Overall performance remained comparable to the previously tested Nintendo
  Switch build.
- Grand Theft Auto: Liberty City Stories showed frequent frame drops.
- Tekken 6 showed occasional frame drops.
- Compatibility and performance vary by game.

## Known Issues

- `JIT using IR` crashes the currently tested games; use regular JIT.
- Vulkan is not supported.
- NetLoader and nxlink launching are not recommended.
- The compatibility test set remains limited and does not guarantee that every
  PSP game will work correctly.
- Performance limitations and frame drops may occur in demanding games.

## Development

Nintendo Switch adaptation, compilation, device testing and release maintenance
were performed by SirSamael.

ChatGPT was used for research, debugging guidance, build investigation,
documentation and release preparation.

---

# v0.5.0 Beta

Experimental Nintendo Switch community beta release based on PPSSPP v1.20.4.

## Audio

- Fixed missing game audio on Nintendo Switch.
- Fixed buzzing and crackling audio.
- Added Switch-specific 48,000 Hz audio output.
- Added a stable 2048-sample SDL audio buffer.
- Updated the mixer to use the audio frequency returned by SDL.

## Video Playback

- Fixed green screens during startup videos and cutscenes.
- Enabled system FFmpeg support.
- Added static FFmpeg dependencies for dav1d and bzip2.

## Adhoc Multiplayer

- Fixed invisible player models during tested multiplayer sessions.
- Improved player movement synchronization during tested quests.
- Improved monster movement and damage synchronization.
- Fixed multiplayer quest teleporting encountered during testing.
- Confirmed multiplayer chat and quest joining.

## Stability and Input

- Fixed the grey screen when exiting to the Homebrew Menu.
- Removed temporary multiplayer diagnostics that caused shutdown instability.
- Fixed crashes from external browser and market buttons.
- Added safe Switch-specific handling for external links.
- Fixed the software keyboard opening automatically during startup.
- Preserved native libnx keyboard support for actual text-entry fields.

## Interface

- Fixed the PPSSPP Homebrew Menu icon.
- Improved Nintendo Switch-specific platform integration.

## Build System

- Added Switch compilation compatibility fixes.
- Added system SDL2 support.
- Added system FFmpeg support.
- Fixed optional FFmpeg component detection.
- Added reusable patches for modified Git submodules.

## Known Issues

- Minor delay or animation skipping may remain in some multiplayer gathering halls.
- Vulkan is not supported.
- JIT using IR may crash.
- NetLoader and nxlink launching are not recommended.
- Game compatibility and performance may vary.

## Development

This release was developed through a vibe-coding workflow using ChatGPT for
research, debugging, patch development, build troubleshooting, testing
assistance and documentation.

All source changes were reviewed, compiled, tested and released by SirSamael.

---

# Changelog

All notable changes to this project will be documented here.

---

# v0.1 - Switch Community Preview

Initial Nintendo Switch community build release.

## Added

- Nintendo Switch libnx build support
- Switch-specific CMake configuration
- OpenGL compatibility fixes
- Switch memory handling improvements
- Network timing diagnostics for Adhoc multiplayer testing
- Submodule patches required for Switch compatibility

## Changed

- Updated platform handling for Nintendo Switch
- Improved compatibility with libnx libraries
- Added Switch-specific build options

## Testing Focus

- PSP game compatibility
- Nintendo Switch performance
- Adhoc multiplayer stability
- Graphics compatibility

## Known Issues

- Experimental build
- Some games may not work correctly
- Multiplayer testing is ongoing
