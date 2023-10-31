#!/usr/bin/env bash

#
# This script is used for rebuild a wasm target (duckdb-wasm-ep) only. 
# So please build this project completely with a stable internet connection 
# before executed this script.
# 
# make wasm_dev
#

throw() { echo -e "fatal: $1" >&2; exit 1; }
execute() { echo "$ $*"; "$@" || throw "Failed to execute '$1'"; }
SECONDS=0;

# change the current directory to the script directory
pushd "$( dirname -- "${BASH_SOURCE[0]}" )/.." >/dev/null || exit 1;

# execute make wasm_dev -j4;
execute ./scripts/wasm_build_lib.sh dev eh;
cd packages/duckdb-wasm || exit 1;
execute yarn run build:release;

echo "done: +${SECONDS}s"
