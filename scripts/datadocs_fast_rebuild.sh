#!/usr/bin/env bash
# shellcheck disable=SC2016

#
# This script is used for rebuild single wasm feature (duckdb-wasm-eh) only. 
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
  echo "  Usage: $bin [--release] [--duckdb] [...features]";
  echo "";
  echo "  Options:";
  echo "";
  echo "    --duckdb      rebuild duckdb core also";
  echo '    --release     build for release `-DCMAKE_BUILD_TYPE=Release -DWASM_MIN_SIZE=1`';
  echo '    --skip-js     skip bundling js files in duckdb-wasm'
  echo "";
  echo "  Common Commands:";
  echo "";
  echo "    $bin                # Build WASM file (eh) for daily development purpose";
  echo "    $bin --release all  # Build all WASM files (eh, mvp, coi) for release purpose";
  echo "";
  exit 0;
}
removedir() { [ -d "$1" ] && execute rm -r -- "$1"; }
SECONDS=0;
build_default_features=( eh );
build_features=();
target_wasm_files=();
build_type='dev';
rebuild_duckdb=;
skip_js_bundle=;
parse_args() {
	while [ "${#@}" -gt 0 ]; do
		arg="$1"; shift;
		case "$arg" in
			-h|--help|help) usage;;
      --release) build_type='relsize';;     # relperf
			--skip-js) skip_js_bundle=1;;
			-dd|--dd|--duckdb) rebuild_duckdb=1;;
      -*) throw  "Unknown option '$arg'";;
      all) build_features=( eh mvp coi );;
      *) build_features+=( "$arg" );
		esac
	done
}
parse_args "${@}";
[ "${#build_features[@]}" == "0" ] && build_features=( "${build_default_features[@]}" );

# change the current directory to the script directory
pushd "$( dirname -- "${BASH_SOURCE[0]}" )/.." >/dev/null || exit 1;


#   ____               
#  / ___|___  _ __ ___ 
# | |   / _ \| '__/ _ \
# | |__| (_) | | |  __/
#  \____\___/|_|  \___|
#region core

execute mkdir -p .ccache/extension;
execute touch .ccache/extension/excel;
execute touch .ccache/extension/json;
execute touch .ccache/extension/datadocs;

# export ENABLE_DATADOCS_EXTENSION=OFF;
for build_feature in "${build_features[@]}"; do
  [ -n "$rebuild_duckdb" ] && 
  removedir "build/dev/${build_feature}/third_party/duckdb/src/duckdb_ep-stamp";

  # execute make wasm_dev -j4;
  execute ./scripts/wasm_build_lib.sh "$build_type" "$build_feature";
  target_wasm_files+=( "packages/duckdb-wasm/src/bindings/duckdb-$build_feature.wasm" );
done

if [ -z "$skip_js_bundle" ]; then
pushd -- packages/duckdb-wasm >/dev/null || exit 1;
execute pwd;
execute yarn run build:release; 
popd >/dev/null || exit 1;
fi

#endregion core


ls -alh "${target_wasm_files[@]}";
echo "done: +${SECONDS}s"
