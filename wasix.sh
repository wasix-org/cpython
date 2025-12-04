#! /bin/bash

set -euxo pipefail

export DEPS_DIR=$(pwd)/../python-wasix-binaries

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
export WASIX_LIBREADLINE_LIBS="-L$DEPS_DIR/lib -lreadline"
# We need to add ncurses/ncursesw because python expects to find <term.h> directly...
export WASIX_CURSES_CFLAGS="-I $DEPS_DIR/include/ncurses -I $DEPS_DIR/include/ncurses/ncursesw"
export WASIX_CURSES_LIBS="-L$DEPS_DIR/lib -lncursesw -lformw -lmenuw"
export WASIX_PANEL_CFLAGS="-I $DEPS_DIR/include/ncurses"
export WASIX_PANEL_LIBS="-L$DEPS_DIR/lib -lpanelw"
export WASIX_LIBB2_CFLAGS="-I $DEPS_DIR/include/libb2"
export WASIX_LIBB2_LIBS="-L$DEPS_DIR/lib -lb2"
export WASIX_BZIP2_CFLAGS="-I $DEPS_DIR/include/bzip2"
export WASIX_BZIP2_LIBS="-L$DEPS_DIR/lib -lbz2_static"
export WASIX_LIBFFI_CFLAGS="-I$DEPS_DIR/include/libffi"
export WASIX_LIBFFI_LIBS="-L$DEPS_DIR/lib -lffi"
export WASIX_LIBSQLITE3_CFLAGS="-I$DEPS_DIR/include/sqlite"
export WASIX_LIBSQLITE3_LIBS="-L$DEPS_DIR/lib -lsqlite3 -licudata -licui18n -licuuc -licutu -licuio"
export WASIX_OPENSSL_DIR="$DEPS_DIR/openssl"

python3 Tools/wasm/wasm_build.py wasix clean
python3 Tools/wasm/wasm_build.py wasix configure
python3 Tools/wasm/wasm_build.py wasix build

pushd builddir/wasix
make install
chmod -R a+rw "$WASIX_INSTALL/cpython"
popd
