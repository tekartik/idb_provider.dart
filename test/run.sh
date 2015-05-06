#/bin/bash

_DIR=$(dirname $(dirname $BASH_SOURCE))

pushd ${_DIR}
pub run test -j 1 -r expanded
popd
