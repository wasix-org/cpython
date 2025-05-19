set -e

WORKDIR=$(pwd)
if test -z "$WASIX_SYSROOT" ; then
    echo "WASIX_SYSROOT is not set. Please set it to the sysroot path (Something like /home/lennart/Documents/wasix-libc/sysroot)."
    exit 1
fi

export WASI_SDK_VERSION=21

export WASI_SDK_PATH="/tmp/wasix-libs/wasi-sdk"
if ! test -d "$WASI_SDK_PATH/.ready" ; then
    mkdir -p $WASI_SDK_PATH
    chmod -R a+rwx $(dirname $WASI_SDK_PATH)
    curl -s -S --location https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-$WASI_SDK_VERSION/wasi-sdk-$WASI_SDK_VERSION.0-linux.tar.gz | \
    tar --strip-components 1 --directory $WASI_SDK_PATH --extract --gunzip
    touch $WASI_SDK_PATH/.ready
fi

WASMER_DIR="/tmp/wasmer"
WASIX_LIBC_TAG="v2024-07-08.1"

export OPENSSL_DIR="/tmp/wasix-libs/openssl"
if ! test -d "$OPENSSL_DIR/.ready" ; then
    mkdir -p $(dirname $OPENSSL_DIR)
    chmod -R a+rwx $(dirname $OPENSSL_DIR)
    git clone https://github.com/wasix-org/openssl $OPENSSL_DIR
    cd $OPENSSL_DIR
    ./wasix.sh
    mkdir -p lib
    cp libcrypto.a lib/libcrypto.a
    cp libssl.a lib/libssl.a
    touch "$OPENSSL_DIR/.ready"
fi

export CROSS_BUILD_PYTHON=cross-build/build
export CROSS_BUILD_WASIX=cross-build/wasix

export WASIX_INSTALL=/tmp/wasix-install
mkdir -p $WASIX_INSTALL

# zlib
export ZLIB_DIR="/tmp/wasix-libs/zlib"
if ! test -d "$ZLIB_DIR/.ready" ; then
    mkdir -p $(dirname $ZLIB_DIR)
    chmod -R a+rwx $(dirname $ZLIB_DIR)
    git clone https://github.com/wasix-org/zlib $ZLIB_DIR
    cd $ZLIB_DIR
    ./wasix.sh
    touch "$ZLIB_DIR/.ready"
fi

# liblzma
export LIBLZMA_DIR="/tmp/wasix-libs/liblzma"
if ! test -d "$LIBLZMA_DIR/.ready" ; then
    mkdir -p $(dirname $LIBLZMA_DIR)
    chmod -R a+rwx $(dirname $LIBLZMA_DIR)
    git clone https://github.com/wasix-org/liblzma $LIBLZMA_DIR
    cd $LIBLZMA_DIR
    ./wasix.sh
    cp src/liblzma/.libs/liblzma.a liblzma.a
    touch "$LIBLZMA_DIR/.ready"
fi


export UTIL_LINUX_DIR="/tmp/wasix-libs/util-linux"
if ! test -d "$UTIL_LINUX_DIR/.ready" ; then
    mkdir -p $(dirname $UTIL_LINUX_DIR)
    chmod -R a+rwx $(dirname $UTIL_LINUX_DIR)
    git clone https://github.com/wasix-org/util-linux $UTIL_LINUX_DIR
    cd $UTIL_LINUX_DIR
    ./wasix.sh
    cp -v .libs/libuuid.a .
    touch "$UTIL_LINUX_DIR/.ready"
fi

export NCURSES_DIR="/tmp/wasix-libs/ncurses"
if ! test -d "$NCURSES_DIR/.ready" ; then
    mkdir -p $(dirname $NCURSES_DIR)
    chmod -R a+rwx $(dirname $NCURSES_DIR)
    git clone https://github.com/wasix-org/ncurses -b wasix-support $NCURSES_DIR
    cd $NCURSES_DIR
    ./wasix.sh
    touch "$NCURSES_DIR/.ready"
fi

export READLINE_DIR="/tmp/wasix-libs/readline/readline"
if ! test -d "$READLINE_DIR/.ready" ; then
    mkdir -p $(dirname $READLINE_DIR)
    chmod -R a+rwx $(dirname $READLINE_DIR)
    git clone https://github.com/wasix-org/readline $READLINE_DIR
    cd $READLINE_DIR
    WASIX_NCURSES=$NCURSES_DIR ./wasix.sh
    touch "$READLINE_DIR/.ready"
fi

cd $WORKDIR

rm Lib/multiprocessing/__pycache__/* || true


WASM_RUNTIME=wasmer \
WASIX_ZLIB_CFLAGS="-I$ZLIB_DIR" \
WASIX_ZLIB_LIBS="-L$ZLIB_DIR -lz " \
WASIX_LIBLZMA_CFLAGS="-I$LIBLZMA_DIR/src/liblzma/api" \
WASIX_LIBLZMA_LIBS="-L$LIBLZMA_DIR -llzma" \
WASIX_LIBUUID_CFLAGS="-I $UTIL_LINUX_DIR/libuuid/src" \
WASIX_LIBUUID_LIBS="-L $UTIL_LINUX_DIR -l uuid" \
WASIX_LIBREADLINE_CFLAGS="-I $READLINE_DIR/.." \
WASIX_LIBREADLINE_LIBS="-L $READLINE_DIR -L $NCURSES_DIR/lib -lreadline -lncurses" \
python3 Tools/wasm/wasm_build.py wasix build -c

cd builddir/wasix
rm -r "$WASIX_INSTALL/cpython" || true
make install
chmod -R a+rw "$WASIX_INSTALL/cpython"