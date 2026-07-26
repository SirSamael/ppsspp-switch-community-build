## Building For Nintendo Switch

Example build configuration:

```bash
mkdir build
cd build

cmake .. -G Ninja \
-DCMAKE_TOOLCHAIN_FILE=/opt/devkitpro/cmake/Switch.cmake \
-DUSE_LIBNX=ON \
-DUSE_FFMPEG=OFF \
-DUSE_DISCORD=OFF \
-DZSTD_BUILD_SHARED=OFF \
-DZSTD_BUILD_STATIC=ON \
-DCMAKE_DISABLE_PRECOMPILE_HEADERS=ON

ninja
The generated Nintendo Switch application can then be tested on compatible hardware.
Current Development Status
This project is currently experimental.
The main focus areas are:
PSP game compatibility
Nintendo Switch performance
Adhoc multiplayer stability
Graphics compatibility
Memory management improvements
Not all games are guaranteed to work at this stage.
