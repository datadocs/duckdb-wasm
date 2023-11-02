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
usage() {
  local bin;
  bin="$(basename "${BASH_SOURCE[0]}")";
  echo "";
  echo "  Usage: $bin [--duckdb] [--datadocs]";
  echo "";
  echo "  Options:";
  echo "";
  echo "    --duckdb      rebuild duckdb core also";
  echo "";
  exit 0;
}
removedir() { [ -d "$1" ] && execute rm -r -- "$1"; }
build_target='eh';
build_type='dev';
rebuild_duckdb=;
parse_args() {
	while [ "${#@}" -gt 0 ]; do
		arg="$1"; shift;
		case "$arg" in
			-h|--help|help) usage;;
			-dd|--dd|--duckdb) rebuild_duckdb=1;;
		esac
	done
}
parse_args "${@}";
SECONDS=0;

# change the current directory to the script directory
pushd "$( dirname -- "${BASH_SOURCE[0]}" )/.." >/dev/null || exit 1;
[ -n "$rebuild_duckdb" ] && removedir "build/dev/${build_target}/third_party/duckdb/src/duckdb_ep-stamp";

# execute make wasm_dev -j4;
execute ./scripts/wasm_build_lib.sh "$build_type" "$build_target";
cd packages/duckdb-wasm || exit 1;
# execute yarn run build:release;
ls -alh "src/bindings/duckdb-$build_target.wasm";

echo "done: +${SECONDS}s"
