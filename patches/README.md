# Nintendo Switch Submodule Patches

These patches contain the submodule changes required by PPSSPP Switch Community
Build v0.7.0.

## Required Patches

    patches/submodules/aemu-postoffice-switch.patch
    patches/submodules/glslang-switch.patch
    patches/submodules/lua-switch.patch
    patches/submodules/nxvk-switch-wsi-cpu-copy.patch

## Initialize Submodules

Run from the repository root:

    git submodule sync --recursive
    git submodule update --init --recursive

## Verify Before Applying

    git -C ext/aemu_postoffice apply --check ../../patches/submodules/aemu-postoffice-switch.patch
    git -C ext/glslang apply --check ../../patches/submodules/glslang-switch.patch
    git -C ext/lua apply --check ../../patches/submodules/lua-switch.patch
    git -C ext/nxvk apply --check ../../patches/submodules/nxvk-switch-wsi-cpu-copy.patch

Each command should complete without an error.

## Apply the Patches

    git -C ext/aemu_postoffice apply ../../patches/submodules/aemu-postoffice-switch.patch
    git -C ext/glslang apply ../../patches/submodules/glslang-switch.patch
    git -C ext/lua apply ../../patches/submodules/lua-switch.patch
    git -C ext/nxvk apply ../../patches/submodules/nxvk-switch-wsi-cpu-copy.patch

The automated release script performs these checks and applies the patches
automatically:

    JOBS=2 ./scripts/build-switch-release.sh

If a patch has already been applied, the automated script detects it and does
not apply it again.
