#! /bin/bash

set -euxo pipefail

export WASI_SDK_PATH=/home/arshia/wasi-sdk
export WASIX_SYSROOT=/home/arshia/repos/wasmer/wasix-libc/sysroot32-ehpic
export DEPS_DIR=$(pwd)/../python-wasix-binaries
export OPENSSL_DIR=$(pwd)/../python-wasix-binaries/openssl

export WASIX_INSTALL=$(pwd)/../cpython-install
mkdir -p $WASIX_INSTALL

export WASM_RUNTIME=wasmer
export WASIX_ZLIB_CFLAGS="-I$DEPS_DIR/include/zlib"
export WASIX_ZLIB_LIBS="-L$DEPS_DIR/lib -lz "
export WASIX_LIBLZMA_CFLAGS="-I$DEPS_DIR/include/lzma"
export WASIX_LIBLZMA_LIBS="-L$DEPS_DIR/lib -llzma"
export WASIX_LIBUUID_CFLAGS="-I $DEPS_DIR/include/libuuid"
export WASIX_LIBUUID_LIBS="-L$DEPS_DIR/lib -luuid"
export WASIX_LIBREADLINE_CFLAGS="-I $DEPS_DIR/include/readline"
export WASIX_LIBREADLINE_LIBS="-L$DEPS_DIR/lib -lreadline -lncurses"
export WASIX_LIBFFI_CFLAGS="-I$DEPS_DIR/include/libffi"
export WASIX_LIBFFI_LIBS="-L$DEPS_DIR/lib -lffi"

python3 Tools/wasm/wasm_build.py wasix clean
python3 Tools/wasm/wasm_build.py wasix configure
python3 Tools/wasm/wasm_build.py wasix build

cd builddir/wasix
rm -r "$WASIX_INSTALL/cpython" || true
make install
chmod -R a+rw "$WASIX_INSTALL/cpython"
