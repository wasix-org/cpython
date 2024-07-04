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
        name = \"python/python\"                      \n
        version = \"$1\"                                \n
        description = \"CPython compiled to wasix\"   \n
        "
    fi

    TOML="
    $PACKAGE                                            \n

    [package]                                           \n
    private = false                                     \n

    [[module]]                                          \n
    name = \"python\"                                   \n
    source = \"python.wasm\"                            \n
    abi = \"wasi\"                                      \n

    [module.interfaces]                                 \n
    wasi = \"0.1.0-unstable\"                           \n

    [[command]]                                         \n
    name = \"python\"                                   \n
    module = \"python\"                                 \n
    runner = \"wasi\"                                   \n

    [command.annotations.wasi]                          \n
    env = ["PYTHONHOME=/cpython"]                       \n

    [env]                                               \n
    \"PYTHONHOME\"=\"/cpython\"                         \n

    [fs]                                                \n
    \"/cpython\"=\"cpython\"                            \n
    "

    echo -e $TOML > wasmer.toml
}

if test -z "$2"; then
  echo "Token is not specified"
  exit 1
fi
TOKEN=$2

if [ "$1" == "push" ]; then
    # populate wasmer.toml
    populate_wasmer_toml

    wasmer package push -vvv --registry "wasmer.io" --token $TOKEN --namespace python --name python .
elif [ "$1" == "publish" ]; then
    if test -z "$3"; then
      echo "Version is not specified"
      exit 1
    fi
    VERSION=$3

    # populate wasmer.toml
    populate_wasmer_toml $VERSION

    wasmer package publish -vvv --registry "wasmer.io" --token $TOKEN --non-interactive .
fi