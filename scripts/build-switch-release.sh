#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VERSION="0.7.0"
RELEASE_NAME="PPSSPP-Switch-Community-Build-v${VERSION}"

BUILD="$ROOT/build-switch-v${VERSION}"
FFMPEG_PREFIX="$ROOT/build-switch-ffmpeg57-prefix"
NXVK_PREFIX="$ROOT/build-switch-nxvk-prefix"
NXVK_EXPAT_BUILD="$ROOT/build-switch-nxvk-expat"
NXVK_EXPAT_SOURCE="$ROOT/ext/nxvk/subprojects/expat-2.5.0"
NXVK_DOCKER="${NXVK_DOCKER:-docker}"
NXVK_CONTAINER="$ROOT/scripts/docker-as-host-user.sh"
NXVK_IMAGE="${NXVK_IMAGE:-nxvk-ppsspp}"
EXPECTED_NXVK_COMMIT="69ec283dbda64e65347a36274efb349122e85363"

DIST="$ROOT/dist/v${VERSION}"
PACKAGE_ROOT="$DIST/package"
APP_DIR="$PACKAGE_ROOT/switch/ppsspp"

NACP="$BUILD/PPSSPP.nacp"
NRO="$BUILD/PPSSPP.nro"

ZIP_PATH="$DIST/${RELEASE_NAME}.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"
SOURCE_NAME="${RELEASE_NAME}-source"
SOURCE_TAR="$DIST/${SOURCE_NAME}.tar"
SOURCE_ARCHIVE="$DIST/${SOURCE_NAME}.tar.gz"
SOURCE_CHECKSUM_PATH="$SOURCE_ARCHIVE.sha256"

ICON="$ROOT/icons/PPSSPP-icon.jpg"

JOBS="${JOBS:-2}"

NACPTOOL="${NACPTOOL:-/opt/devkitpro/tools/bin/nacptool}"
ELF2NRO="${ELF2NRO:-/opt/devkitpro/tools/bin/elf2nro}"
PORTLIBS_PREFIX="${PORTLIBS_PREFIX:-/opt/devkitpro/portlibs/switch}"

apply_submodule_patch() {
  local submodule="$1"
  local patch="$2"
  local name="$3"

  if git -C "$submodule" apply --check "$patch" >/dev/null 2>&1; then
    echo "Applying $name patch..."
    git -C "$submodule" apply "$patch"
  elif git -C "$submodule" apply --reverse --check "$patch" >/dev/null 2>&1; then
    echo "$name patch is already applied."
  else
    echo "ERROR: $name patch cannot be applied cleanly."
    return 1
  fi
}

report_dkp_package() {
  local package="$1"
  local pacman="${DEVKITPRO:-/opt/devkitpro}/pacman/bin/pacman"

  if [ -x "$pacman" ]; then
    "$pacman" -Q "$package" 2>/dev/null || echo "$package unavailable"
  else
    echo "$package version unavailable (devkitPro pacman not found)"
  fi
}

create_source_archive() {
  local submodule
  local submodule_tar

  echo "=== CREATING COMPLETE CORRESPONDING SOURCE ARCHIVE ==="
  git archive --format=tar --prefix="$SOURCE_NAME/" HEAD > "$SOURCE_TAR"

  while IFS= read -r submodule; do
    submodule_tar="$(mktemp "$DIST/nxvk-source.XXXXXX.tar")"
    git -C "$ROOT/$submodule" archive --format=tar --prefix="$SOURCE_NAME/$submodule/" HEAD > "$submodule_tar"
    tar --concatenate --file="$SOURCE_TAR" "$submodule_tar"
    rm -f "$submodule_tar"
  done < <(git submodule foreach --recursive --quiet 'printf "%s\\n" "$displaypath"')

  gzip -n -f "$SOURCE_TAR"
  sha256sum "$SOURCE_ARCHIVE" > "$SOURCE_CHECKSUM_PATH"
}

echo "=== PPSSPP Switch Community Build v${VERSION} ==="
echo "Repository: $ROOT"
echo "Build:      $BUILD"
echo "Output:     $DIST"
echo "Jobs:       $JOBS"
echo

cd "$ROOT"

if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "ERROR: Release builds must start from committed top-level source so the source archive matches the binary."
  return 1 2>/dev/null || false
fi

if [ "${SKIP_NXVK_BUILD:-0}" != "1" ]; then
  echo "=== VERIFYING NXVK CONTAINER RUNTIME ==="

  if ! command -v "$NXVK_DOCKER" >/dev/null 2>&1 || ! "$NXVK_DOCKER" version >/dev/null 2>&1; then
    echo "ERROR: NXVK requires a working Docker-compatible runtime ('$NXVK_DOCKER')."
    echo "Set NXVK_DOCKER to a working Docker-compatible runtime command."
    return 1 2>/dev/null || false
  fi
fi

echo "=== INITIALIZING SUBMODULES ==="
git submodule sync --recursive
git submodule update --init --recursive

echo
echo "=== VERIFYING FFMPEG REVISION ==="

EXPECTED_FFMPEG_COMMIT="82049cca2e4c1516ed00a77b502a21f91b7843f4"
CURRENT_FFMPEG_COMMIT="$(git -C "$ROOT/ffmpeg" rev-parse HEAD)"

echo "Expected: $EXPECTED_FFMPEG_COMMIT"
echo "Current:  $CURRENT_FFMPEG_COMMIT"

if [ "$CURRENT_FFMPEG_COMMIT" != "$EXPECTED_FFMPEG_COMMIT" ]; then
  echo "ERROR: The FFmpeg submodule is not at the required revision."
  return 1 2>/dev/null || false
fi

echo
echo "=== VERIFYING NXVK REVISION ==="

CURRENT_NXVK_COMMIT="$(git -C "$ROOT/ext/nxvk" rev-parse HEAD)"

echo "Expected: $EXPECTED_NXVK_COMMIT"
echo "Current:  $CURRENT_NXVK_COMMIT"

if [ "$CURRENT_NXVK_COMMIT" != "$EXPECTED_NXVK_COMMIT" ]; then
  echo "ERROR: The NXVK submodule is not at the required revision."
  return 1 2>/dev/null || false
fi

echo
echo "=== APPLYING SWITCH SUBMODULE PATCHES ==="

apply_submodule_patch \
  "$ROOT/ext/aemu_postoffice" \
  "$ROOT/patches/submodules/aemu-postoffice-switch.patch" \
  "aemu_postoffice"

apply_submodule_patch \
  "$ROOT/ext/glslang" \
  "$ROOT/patches/submodules/glslang-switch.patch" \
  "glslang"

apply_submodule_patch \
  "$ROOT/ext/lua" \
  "$ROOT/patches/submodules/lua-switch.patch" \
  "lua"

apply_submodule_patch \
  "$ROOT/ext/nxvk" \
  "$ROOT/patches/submodules/nxvk-switch-wsi-cpu-copy.patch" \
  "NXVK Switch WSI CPU-copy"

echo
echo "=== BUILDING ISOLATED FFMPEG 57 ==="

if [ "${SKIP_FFMPEG_BUILD:-0}" = "1" ]; then
  echo "Reusing existing isolated FFmpeg 57 prefix."
else
  JOBS="$JOBS" "$ROOT/scripts/build-switch-ffmpeg57.sh"
fi

for library in \
  libavcodec.a \
  libavformat.a \
  libavutil.a \
  libswresample.a \
  libswscale.a
do
  if [ ! -f "$FFMPEG_PREFIX/lib/$library" ]; then
    echo "ERROR: Missing FFmpeg library: $library"
    return 1 2>/dev/null || false
  fi
done

echo
echo "=== BUILDING NXVK + ZINK ==="

if [ "${SKIP_NXVK_BUILD:-0}" = "1" ]; then
  echo "Reusing existing NXVK + Zink artifacts."
else
  make -C "$ROOT/ext/nxvk" image \
    CONTAINER="$NXVK_CONTAINER" \
    DOCKER_BIN="$NXVK_DOCKER"
  DOCKER_BIN="$NXVK_DOCKER" "$NXVK_CONTAINER" build -t "$NXVK_IMAGE" -f "$ROOT/scripts/nxvk.Dockerfile" "$ROOT"
  make -C "$ROOT/ext/nxvk" gl \
    CONTAINER="$NXVK_CONTAINER" \
    DOCKER_BIN="$NXVK_DOCKER" \
    IMAGE="$NXVK_IMAGE" \
    DEVKITPRO="${DEVKITPRO:-/opt/devkitpro}"
fi

if [ ! -f "$ROOT/ext/nxvk/switch/build/pkg/lib/libnvk_gl.a" ]; then
  echo "ERROR: NXVK did not produce libnvk_gl.a."
  return 1 2>/dev/null || false
fi

rm -rf "$NXVK_PREFIX"
mkdir -p "$NXVK_PREFIX/lib" "$NXVK_PREFIX/include"
cp -a "$ROOT/ext/nxvk/switch/build/pkg/lib/." "$NXVK_PREFIX/lib/"
cp -a "$ROOT/ext/nxvk/include/vulkan" "$ROOT/ext/nxvk/include/vk_video" "$NXVK_PREFIX/include/"

# Mesa's XML configuration path needs Expat.  Prefer devkitPro's portlib, but
# build NXVK's pinned vendored source into the local prefix when it is absent.
if [ ! -f "$PORTLIBS_PREFIX/lib/libexpat.a" ]; then
  if [ ! -f "$NXVK_EXPAT_SOURCE/CMakeLists.txt" ]; then
    echo "ERROR: NXVK's vendored Expat source is missing."
    return 1 2>/dev/null || false
  fi

  echo "=== BUILDING VENDORED EXPAT FOR NXVK ==="
  rm -rf "$NXVK_EXPAT_BUILD"
  cmake \
    -S "$NXVK_EXPAT_SOURCE" \
    -B "$NXVK_EXPAT_BUILD" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/cmake/Switch.cmake \
    -DCMAKE_INSTALL_PREFIX="$NXVK_PREFIX" \
    -DEXPAT_SHARED_LIBS=OFF \
    -DEXPAT_BUILD_TOOLS=OFF \
    -DEXPAT_BUILD_EXAMPLES=OFF \
    -DEXPAT_BUILD_TESTS=OFF \
    -DEXPAT_BUILD_DOCS=OFF
  cmake --build "$NXVK_EXPAT_BUILD" --parallel "$JOBS"
  cmake --install "$NXVK_EXPAT_BUILD"
fi

if [ ! -f "$NXVK_PREFIX/lib/pkgconfig/nxvk-gl.pc" ]; then
  echo "ERROR: NXVK did not stage nxvk-gl.pc."
  return 1 2>/dev/null || false
fi

echo
echo "=== CONFIGURING PPSSPP ==="

rm -rf "$BUILD"

cmake \
  -S "$ROOT" \
  -B "$BUILD" \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/cmake/Switch.cmake \
  -DCMAKE_PREFIX_PATH="$PORTLIBS_PREFIX" \
  -DUSE_LIBNX=ON \
  -DSWITCH_USE_NXVK=ON \
  -DNXVK_PREFIX="$NXVK_PREFIX" \
  -DPPSSPP_GIT_VERSION_OVERRIDE="v${VERSION}" \
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
  -DFFMPEG_DIR="$FFMPEG_PREFIX" \
  -DUSE_DISCORD=OFF \
  -DUSE_SYSTEM_ZSTD=OFF \
  -DARMIPS_USE_STD_FILESYSTEM=ON \
  -DCMAKE_DISABLE_PRECOMPILE_HEADERS=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5

echo
echo "=== COMPILING PPSSPP ==="

cmake --build "$BUILD" --parallel "$JOBS"

ELF="$BUILD/PPSSPPSDL.elf"

if [ ! -f "$ELF" ]; then
  echo "ERROR: Build did not produce PPSSPPSDL.elf."
  return 1 2>/dev/null || false
fi

if [ ! -d "$BUILD/assets" ]; then
  echo "ERROR: Build did not generate the release assets directory."
  return 1 2>/dev/null || false
fi

if [ ! -f "$ICON" ]; then
  echo "ERROR: Release icon is missing: $ICON"
  return 1 2>/dev/null || false
fi

echo
echo "=== GENERATING HOMEBREW METADATA ==="

"$NACPTOOL" --create \
  "PPSSPP Switch Community Build" \
  "SirSamael" \
  "$VERSION" \
  "$NACP"

echo
echo "=== GENERATING NRO ==="

"$ELF2NRO" \
  "$ELF" \
  "$NRO" \
  --icon="$ICON" \
  --nacp="$NACP"

if [ ! -f "$NRO" ]; then
  echo "ERROR: elf2nro did not produce PPSSPP.nro."
  return 1 2>/dev/null || false
fi

echo
echo "=== CREATING SD-CARD PACKAGE ==="

rm -rf "$DIST"
mkdir -p "$APP_DIR"

cp "$NRO" "$APP_DIR/PPSSPP.nro"
cp -a "$BUILD/assets" "$APP_DIR/assets"
cp "$ROOT/LICENSE.TXT" "$PACKAGE_ROOT/LICENSE.TXT"
cp "$ROOT/THIRD_PARTY_NOTICES.md" "$PACKAGE_ROOT/THIRD_PARTY_NOTICES.md"
mkdir -p "$PACKAGE_ROOT/licenses/nxvk"
cp -a "$ROOT/ext/nxvk/licenses/." "$PACKAGE_ROOT/licenses/nxvk/"

{
  echo "PPSSPP source revision: $(git rev-parse HEAD)"
  echo "NXVK source revision: $CURRENT_NXVK_COMMIT"
  echo "NXVK Mesa base: 26.1.4"
  echo "FFmpeg source revision: $CURRENT_FFMPEG_COMMIT"
  report_dkp_package devkitA64
  report_dkp_package libnx
  report_dkp_package switch-sdl2
  report_dkp_package switch-libexpat
  report_dkp_package switch-zlib
} > "$PACKAGE_ROOT/BUILD-METADATA.txt"

ASSET_COUNT="$(find "$APP_DIR/assets" -type f | wc -l | tr -d ' ')"

echo "Packaged asset files: $ASSET_COUNT"

if [ "$ASSET_COUNT" -ne 185 ]; then
  echo "ERROR: Expected 185 generated asset files."
  return 1 2>/dev/null || false
fi

create_source_archive

echo
echo "=== CREATING ZIP ARCHIVE ==="

python3 - "$PACKAGE_ROOT" "$ZIP_PATH" <<'PY'
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
import sys

package_root = Path(sys.argv[1])
zip_path = Path(sys.argv[2])

with ZipFile(
    zip_path,
    "w",
    compression=ZIP_DEFLATED,
    compresslevel=9,
    allowZip64=True,
) as archive:
    for path in sorted(package_root.rglob("*")):
        if path.is_file():
            archive.write(path, path.relative_to(package_root))
PY

(
  cd "$DIST"
  sha256sum "$(basename "$ZIP_PATH")" > "$(basename "$CHECKSUM_PATH")"
)

echo
echo "=== RELEASE VERIFICATION ==="

echo "NRO:"
ls -lh "$APP_DIR/PPSSPP.nro"
sha256sum "$APP_DIR/PPSSPP.nro"

echo
echo "Assets:"
echo "$ASSET_COUNT files"
du -sh "$APP_DIR/assets"

echo
echo "Archive:"
ls -lh "$ZIP_PATH"
cat "$CHECKSUM_PATH"

echo
echo "Complete corresponding source:"
ls -lh "$SOURCE_ARCHIVE"
cat "$SOURCE_CHECKSUM_PATH"

echo
echo "Archive root:"
python3 - "$ZIP_PATH" <<'PY'
from zipfile import ZipFile
import sys

with ZipFile(sys.argv[1]) as archive:
    names = archive.namelist()

print("\n".join(names[:20]))

if not any(name.startswith("switch/ppsspp/") for name in names):
    raise SystemExit("ERROR: Archive does not contain switch/ppsspp/")
PY

echo
echo "Build and packaging completed successfully."
echo "Release ZIP: $ZIP_PATH"
echo "Checksum:    $CHECKSUM_PATH"
echo "Source:      $SOURCE_ARCHIVE"
echo "Checksum:    $SOURCE_CHECKSUM_PATH"
