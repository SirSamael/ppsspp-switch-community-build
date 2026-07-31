#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VERSION="0.6.0"
RELEASE_NAME="PPSSPP-Switch-Community-Build-v${VERSION}"

BUILD="$ROOT/build-switch-v${VERSION}"
FFMPEG_PREFIX="$ROOT/build-switch-ffmpeg57-prefix"

DIST="$ROOT/dist/v${VERSION}"
PACKAGE_ROOT="$DIST/package"
APP_DIR="$PACKAGE_ROOT/switch/ppsspp"

NACP="$BUILD/PPSSPP.nacp"
NRO="$BUILD/PPSSPP.nro"

ZIP_PATH="$DIST/${RELEASE_NAME}.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

ICON="$ROOT/icons/PPSSPP-icon.jpg"

JOBS="${JOBS:-2}"

NACPTOOL="${NACPTOOL:-/opt/devkitpro/tools/bin/nacptool}"
ELF2NRO="${ELF2NRO:-/opt/devkitpro/tools/bin/elf2nro}"

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

echo "=== PPSSPP Switch Community Build v${VERSION} ==="
echo "Repository: $ROOT"
echo "Build:      $BUILD"
echo "Output:     $DIST"
echo "Jobs:       $JOBS"
echo

cd "$ROOT"

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

echo
echo "=== BUILDING ISOLATED FFMPEG 57 ==="

JOBS="$JOBS" "$ROOT/scripts/build-switch-ffmpeg57.sh"

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
echo "=== CONFIGURING PPSSPP ==="

rm -rf "$BUILD"

cmake \
  -S "$ROOT" \
  -B "$BUILD" \
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

ASSET_COUNT="$(find "$APP_DIR/assets" -type f | wc -l | tr -d ' ')"

echo "Packaged asset files: $ASSET_COUNT"

if [ "$ASSET_COUNT" -ne 185 ]; then
  echo "ERROR: Expected 185 generated asset files."
  return 1 2>/dev/null || false
fi

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
