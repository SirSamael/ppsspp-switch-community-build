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
