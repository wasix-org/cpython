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

python3 Tools/wasm/wasm_build.py wasix build -c

rm -rf "artifacts/wasix-install" && mkdir -p "artifacts/wasix-install"
make -C builddir/wasix install DESTDIR="$(pwd)/artifacts/wasix-install"