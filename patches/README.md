# Switch Submodule Patches

These patches contain the submodule changes required for this Nintendo Switch build.

After cloning the repository and initializing submodules, apply them from the project root:

git -C ext/aemu_postoffice apply ../../patches/submodules/aemu_postoffice-switch.patch
git -C ext/glslang apply ../../patches/submodules/glslang-switch.patch
git -C ext/lua apply ../../patches/submodules/lua-switch.patch
