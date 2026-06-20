#!/bin/bash
# Build script for Blender Android ARM64
# Usage: ./build_android.sh [--clean] [--skip-datatoc]
# Requires: Android NDK, LIB_DIR set or passed

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLENDER_ROOT="$SCRIPT_DIR"

# --- Configuration (override via environment) ---
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_SDK_ROOT/ndk/26.1.10909125}"
export LIB_DIR="${LIB_DIR:-$BLENDER_ROOT/../lib-android_arm64}"
BUILD_DIR="${BUILD_DIR:-$BLENDER_ROOT/build_android}"
CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}"
JOBS="${JOBS:-$(nproc)}"

# --- Parse args ---
SKIP_DATATOC=false
CLEAN=false
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=true ;;
    --skip-datatoc) SKIP_DATATOC=true ;;
  esac
done

echo "=== Blender Android ARM64 Build ==="
echo "NDK:      $ANDROID_NDK_HOME"
echo "LIB_DIR:  $LIB_DIR"
echo "Build:    $BUILD_DIR/$CMAKE_BUILD_TYPE"
echo "Jobs:     $JOBS"

# --- Check NDK ---
TOOLCHAIN="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"
if [ ! -f "$TOOLCHAIN" ]; then
  echo "ERROR: Android NDK toolchain not found at $TOOLCHAIN"
  echo "Set ANDROID_NDK_HOME or install NDK 26.1"
  exit 1
fi

# --- Check LIB_DIR ---
if [ ! -d "$LIB_DIR" ]; then
  echo "ERROR: LIB_DIR not found at $LIB_DIR"
  echo "Clone the libs: git clone https://github.com/dshawshank/lib-android_arm64.git \"$LIB_DIR\""
  exit 1
fi

# --- Build host datatoc (native x86_64) ---
if [ "$SKIP_DATATOC" = false ]; then
  echo ""
  echo "=== Building datatoc (host) ==="
  DATATOC_DIR="$BUILD_DIR/host_tools"
  mkdir -p "$DATATOC_DIR"
  
  # Simple native compile of datatoc
  gcc -O2 -o "$DATATOC_DIR/datatoc" "$BLENDER_ROOT/source/blender/datatoc/datatoc.c" -lm
  echo "datatoc built: $DATATOC_DIR/datatoc"
  
  # datatoc_icon needs libpng
  PNG_INC="$LIB_DIR/Png/include/libpng-1.6.40"
  PNG_LIB="$LIB_DIR/Png/lib/libpng16.so"
  ZLIB_LIB="$LIB_DIR/OpenCOLLADA/lib/libzlib.so"
  if [ -f "$PNG_LIB" ]; then
    gcc -O2 -o "$DATATOC_DIR/datatoc_icon" \
      -I"$PNG_INC" \
      "$BLENDER_ROOT/source/blender/datatoc/datatoc_icon.c" \
      "$PNG_LIB" "$ZLIB_LIB" -lm 2>/dev/null && \
    echo "datatoc_icon built: $DATATOC_DIR/datatoc_icon" || \
    echo "Warning: datatoc_icon build failed (libpng not found)"
  else
    echo "Warning: libpng not found, datatoc_icon won't be available"
  fi
fi

# --- Clean if requested ---
if [ "$CLEAN" = true ]; then
  echo ""
  echo "=== Cleaning build directory ==="
  rm -rf "$BUILD_DIR/$CMAKE_BUILD_TYPE"
fi

# --- Configure CMake ---
echo ""
echo "=== Configuring CMake ==="
mkdir -p "$BUILD_DIR/$CMAKE_BUILD_TYPE"
cd "$BUILD_DIR/$CMAKE_BUILD_TYPE"

cmake "$BLENDER_ROOT" \
  -G "Ninja" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
  -DLIB_DIR="$LIB_DIR" \
  -DDATATOC_EXECUTABLE="$BUILD_DIR/host_tools/datatoc" \
  -DDATATOC_ICON_EXECUTABLE="$BUILD_DIR/host_tools/datatoc_icon" \
  -DWITH_BLENDER=ON \
  -DWITH_PYTHON=ON \
  -DWITH_INTERNATIONAL=ON \
  -DWITH_CODEC_FFMPEG=ON \
  -DWITH_OPENAL=ON \
  -DWITH_SDL=OFF \
  -DWITH_GHOST_X11=OFF \
  -DWITH_GHOST_WAYLAND=OFF \
  -DWITH_GHOST_XINPUT=OFF \
  -DWITH_X11_XINPUT=OFF \
  -DWITH_X11_XF86VMODE=OFF \
  -DWITH_X11_XFIXES=OFF \
  -DWITH_X11_ALPHA=OFF \
  -DWITH_JACK=OFF \
  -DWITH_PULSEAUDIO=OFF \
  -DWITH_SDL_DYNLOAD=OFF \
  -DWITH_OPENCOLLADA=ON \
  -DWITH_OPENSUBDIV=ON \
  -DWITH_OPENVDB=ON \
  -DWITH_NANOVDB=ON \
  -DWITH_ALEMBIC=ON \
  -DWITH_USD=OFF \
  -DWITH_MATERIALX=OFF \
  -DWITH_CYCLES=ON \
  -DWITH_CYCLES_OSL=OFF \
  -DWITH_CYCLES_EMBREE=ON \
  -DWITH_CYCLES_PATH_GUIDING=ON \
  -DWITH_TBB=ON \
  -DWITH_OPENIMAGEDENOISE=ON \
  -DWITH_FFTW3=ON \
  -DWITH_GMP=ON \
  -DWITH_POTRACE=ON \
  -DWITH_HARU=OFF \
  -DWITH_LLVM=OFF \
  -DWITH_LZO=OFF \
  -DWITH_GTESTS=OFF \
  -DWITH_DOC_MANPAGE=OFF \
  -DWITH_OPENGL_RENDER_TESTS=OFF \
  -DWITH_OPENGL_DRAW_TESTS=OFF \
  -DWITH_VULKAN_BACKEND=OFF \
  -DWITH_MEM_JEMALLOC=OFF \
  -DWITH_INSTALL_PORTABLE=ON \
  -DWITH_BUILDINFO=OFF \
  -DWITH_COMPILER_CCACHE=ON \
  2>&1 | tee cmake_config.log

echo ""
echo "=== CMake configuration complete ==="

# --- Build ---
echo ""
echo "=== Building Blender... ==="
ninja -j"$JOBS" 2>&1 | tee build.log

echo ""
echo "=== Build complete ==="
echo "Output: $BUILD_DIR/$CMAKE_BUILD_TYPE/bin/"
