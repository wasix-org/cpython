#!/usr/bin/env bash
set -ex
if test -z "$WASIXCC_SYSROOT" ; then
    echo "WASIXCC_SYSROOT is not set. Please set it to the sysroot path (Something like /home/lennart/Documents/wasix-libc/sysroot)."
    exit 1
fi

export WASI_SDK_PATH="${WASIX_LLVM:-$(dirname $(dirname $(which clang)))}"
export WASIX_PKG_CONFIG_SYSROOT_DIR="$WASIXCC_SYSROOT"
export WASIX_PKG_CONFIG_LIBDIR="$WASIXCC_SYSROOT/usr/local/lib/wasm32-wasi/pkgconfig"
export WASM_RUNTIME=wasmer

export WASIXCC_RUN_WASM_OPT="no"
export WASIXCC_WASM_EXCEPTIONS="yes"
export WASIXCC_PIC="yes"
export WASIXCC_INCLUDE_CPP_SYMBOLS="yes"
# Add the other locations to the search path
export WASIXCC_COMPILER_FLAGS="-Wl,-L${WASIXCC_SYSROOT}/usr/local/lib/wasm32-wasi:-I${WASIXCC_SYSROOT}/usr/local/include:-Wl,-mllvm,--wasm-enable-eh:-Wl,-mllvm,--wasm-enable-sjlj:-Wl,-mllvm,--wasm-use-legacy-eh=false:-Wl,-mllvm,--exception-model=wasm:-iwithsysroot:/usr/local/include/c++/v1"
# Make clang emit the non-legacy exception handling directly
export WASIXCC_LINKER_FLAGS="-mllvm:--wasm-enable-eh:-mllvm:--wasm-enable-sjlj:-mllvm:--wasm-use-legacy-eh=false:-mllvm:--exception-model=wasm"

python3 Tools/wasm/wasm_build.py wasix build -c

rm -rf "artifacts/wasix-install" && mkdir -p "artifacts/wasix-install"
make -C builddir/wasix install DESTDIR="$(pwd)/artifacts/wasix-install"