#!/bin/bash

# ./wasmer-release push    <TOKEN> <OWNER>
# ./wasmer-release publish <TOKEN> <OWNER> <VERSION>

set -xe


populate_wasmer_toml() {
    if [ -z "$1" ]; then
        PACKAGE=""
    else
        PACKAGE="
        [package]                                   \n
        name = "python/python"                      \n
        version = $1                                \n
        description = "CPython compiled to wasix"   \n
        "
    fi

    TOML="
    $PACKAGE                                        \n

    [[module]]                                      \n
    name = "python"                                 \n
    source = "python.wasm"                          \n
    abi = "wasi"

    [module.interfaces]                             \n
    wasi = "0.1.0-unstable"                         \n

    [[command]]                                     \n
    name = "python"                                 \n
    module = "python"                               \n

    [[env]]
    "PYTHONHOME"="/cpython"                         \n

    [fs]
    "/cpython"="$WASIX_INSTALL/cpython"
    "

    echo $TOML > $WASIX_INSTALL/wasmer.toml
}

if test -z "$2"; then
  echo "Token is not specified"
  exit 1
fi
TOKEN=$2

if test -z "$3"; then
  echo "Owner is not specified"
  exit 1
fi
OWNER=$3

if [ "$1" == "push" ]; then
    # populate wasmer.toml
    populate_wasmer_toml

    wasmer package push --registry "wasmer.io" --token $TOKEN --owner $OWNER .
elif [ "$1" == "publish" ]; then
    if test -z "$4"; then
      echo "Version is not specified"
      exit 1
    fi
    VERSION=$3

    # populate wasmer.toml
    populate_wasmer_toml $VERSION

    wasmer package publish --registry "wasmer.io" --token $TOKEN --owner $OWNER $WASIX_INSTALL
fi