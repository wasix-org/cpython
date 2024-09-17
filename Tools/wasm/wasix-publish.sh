#!/bin/bash

# ./wasmer-release push    <TOKEN>
# ./wasmer-release publish <TAG> <TOKEN>

set -xe

if [ "$1" == "push" ]; then
    wasmer package push  --registry "wasmer.io" --token $2 --non-interactive .
elif [ "$1" == "publish" ]; then
    version=$(echo $2 | sed 's/^v//')

    wasmer package publish --registry "wasmer.io" --token $3 --non-interactive --version $version .
fi