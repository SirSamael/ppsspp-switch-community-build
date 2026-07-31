#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/ffmpeg"
BUILD="$ROOT/build-switch-ffmpeg57"
PREFIX="$ROOT/build-switch-ffmpeg57-prefix"

EXPECTED_FFMPEG_COMMIT="82049cca2e4c1516ed00a77b502a21f91b7843f4"
JOBS="${JOBS:-$(nproc)}"

export DEVKITPRO="${DEVKITPRO:-/opt/devkitpro}"
export DEVKITA64="${DEVKITA64:-$DEVKITPRO/devkitA64}"
export PORTLIBS_PREFIX="${PORTLIBS_PREFIX:-$DEVKITPRO/portlibs/switch}"

export PATH="$DEVKITA64/bin:$DEVKITPRO/tools/bin:$PORTLIBS_PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PORTLIBS_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

echo "=== PPSSPP Switch FFmpeg 57 Build ==="
echo "Repository: $ROOT"
echo "Source:     $SOURCE"
echo "Build:      $BUILD"
echo "Prefix:     $PREFIX"
echo "Jobs:       $JOBS"
echo

if [ ! -f "$SOURCE/configure" ]; then
  echo "ERROR: FFmpeg submodule is not initialized."
  echo "Run: git submodule update --init --recursive"
  return 1 2>/dev/null || false
fi

CURRENT_FFMPEG_COMMIT="$(git -C "$SOURCE" rev-parse HEAD)"

if [ "$CURRENT_FFMPEG_COMMIT" != "$EXPECTED_FFMPEG_COMMIT" ]; then
  echo "ERROR: Incorrect FFmpeg source revision."
  echo "Expected: $EXPECTED_FFMPEG_COMMIT"
  echo "Current:  $CURRENT_FFMPEG_COMMIT"
  return 1 2>/dev/null || false
fi

for tool in \
  "$DEVKITA64/bin/aarch64-none-elf-gcc" \
  "$DEVKITA64/bin/aarch64-none-elf-g++" \
  make \
  pkg-config
do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: Required tool not found: $tool"
    return 1 2>/dev/null || false
  fi
done

rm -rf "$BUILD" "$PREFIX"
mkdir -p "$BUILD" "$PREFIX"

cd "$BUILD"

"$SOURCE/configure" \
  --prefix="$PREFIX" \
  --enable-cross-compile \
  --arch=aarch64 \
  --cross-prefix=aarch64-none-elf- \
  --target-os=horizon \
  --extra-cflags="-g -D__SWITCH__ -D_GNU_SOURCE -O3 -march=armv8-a -mtune=cortex-a57 -mtp=soft -fPIE -pie -ffunction-sections -fdata-sections -ftls-model=local-exec" \
  --extra-cxxflags="-g -D__SWITCH__ -D_GNU_SOURCE -O3 -march=armv8-a -mtune=cortex-a57 -mtp=soft -fPIE -pie -ffunction-sections -fdata-sections -ftls-model=local-exec" \
  --extra-ldflags="-g -fPIE -pie -L${PORTLIBS_PREFIX}/lib -L${DEVKITPRO}/libnx/lib" \
  --disable-shared \
  --enable-static \
  --enable-zlib \
  --disable-runtime-cpudetect \
  --disable-everything \
  --disable-filters \
  --disable-programs \
  --disable-network \
  --disable-avfilter \
  --disable-postproc \
  --disable-encoders \
  --disable-protocols \
  --disable-hwaccels \
  --disable-doc \
  --enable-decoder=h264 \
  --enable-decoder=mpeg4 \
  --enable-decoder=mpeg2video \
  --enable-decoder=mjpeg \
  --enable-decoder=mjpegb \
  --enable-decoder=aac \
  --enable-decoder=aac_latm \
  --enable-decoder=atrac3 \
  --enable-decoder=atrac3p \
  --enable-decoder=mp3 \
  --enable-decoder=pcm_s16le \
  --enable-decoder=pcm_s8 \
  --enable-encoder=huffyuv \
  --enable-encoder=ffv1 \
  --enable-encoder=mjpeg \
  --enable-encoder=pcm_s16le \
  --enable-demuxer=h264 \
  --enable-demuxer=m4v \
  --enable-demuxer=mpegvideo \
  --enable-demuxer=mpegps \
  --enable-demuxer=mp3 \
  --enable-demuxer=avi \
  --enable-demuxer=aac \
  --enable-demuxer=pmp \
  --enable-demuxer=oma \
  --enable-demuxer=pcm_s16le \
  --enable-demuxer=pcm_s8 \
  --enable-demuxer=wav \
  --enable-muxer=avi \
  --enable-parser=h264 \
  --enable-parser=mpeg4video \
  --enable-parser=mpegaudio \
  --enable-parser=mpegvideo \
  --enable-parser=aac \
  --enable-parser=aac_latm

make -j"$JOBS"
make install

echo
echo "=== VERIFYING REQUIRED LIBRARIES ==="

required_libraries=(
  libavcodec.a
  libavformat.a
  libavutil.a
  libswresample.a
  libswscale.a
)

missing=0

for library in "${required_libraries[@]}"; do
  path="$PREFIX/lib/$library"

  if [ -f "$path" ]; then
    ls -lh "$path"
  else
    echo "MISSING: $path"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "ERROR: One or more required FFmpeg libraries were not generated."
  return 1 2>/dev/null || false
fi

echo
echo "FFmpeg 57 Switch build completed successfully."
echo "Use this CMake value:"
echo "-DFFMPEG_DIR=\"$PREFIX\""
