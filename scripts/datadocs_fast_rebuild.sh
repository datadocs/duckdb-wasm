#!/usr/bin/env bash
# shellcheck disable=SC2016

#
# Description:
#
#   A bash script for building DuckDB WASM with the Datadocs extension
#   (This script has been tested on Ubuntu 24.04 and MacOS Sequoia 15)
# 
# Usage:   datadocs_fast_rebuild.sh [--release] [--duckdb] [...features]
# Options: please read the `usage` function below for details
# Author:  Liu Yue @hangxingliu
# Version: 2025-04-11
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
      --release) build_type='relperf';;     # relperf
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

#
# 0. precheck
#
command -v emcc >/dev/null || throw "emsdk <https://github.com/emscripten-core/emsdk> is not installed! ";
command -v cmake >/dev/null || throw "cmake is not installed!";
command -v node >/dev/null || throw "node.js is not installed!";

# change the current directory to the script directory
pushd "$( dirname -- "${BASH_SOURCE[0]}" )/.." >/dev/null || exit 1;

log_file="./scripts/logs/build-$(date "+%Y%m%d-%H%M").log"; 
execute mkdir -p "$(dirname -- "${log_file}")";
(
  printf "Diagnosis:\n";
  printf "$ %s\n%s\n\n" "emcc --version"  "$(emcc --version)";
  printf "$ %s\n%s\n\n" "node --version"  "$(node --version)";
  printf "$ %s\n%s\n\n" "cmake --version" "$(cmake --version)";
  printf "$ %s\n%s\n\n" "git log -n 1"     "$(git log -n 1)";
  printf "$ %s\n%s\n\n" "git status --untracked-files=all --short" \
    "$(git status --untracked-files=all --short)";
) > "${log_file}";
printf "\n  log file: %s\n\n" "$log_file";


#   ____               
#  / ___|___  _ __ ___ 
# | |   / _ \| '__/ _ \
# | |__| (_) | | |  __/
#  \____\___/|_|  \___|
#region core

execute mkdir -p .ccache/extension;
execute touch .ccache/extension/json;
execute touch .ccache/extension/datadocs;

#
# 1. apply patch files:
#
execute make apply_patches
print_cmd bash scripts/datadocs_clean_files.sh
bash scripts/datadocs_clean_files.sh >/dev/null;

#
# 2. build each features:
#
# export ENABLE_DATADOCS_EXTENSION=OFF;
for build_feature in "${build_features[@]}"; do
  [ -n "$rebuild_duckdb" ] && 
    removedir "build/${build_type}/${build_feature}/third_party/duckdb/src/duckdb_ep-stamp";
  target_wasm_files+=( "packages/duckdb-wasm/src/bindings/duckdb-$build_feature.wasm" );
  
  #
  # The core of the building:
  #
  # execute make wasm_dev -j4;
  build_cmd=( bash ./scripts/wasm_build_lib.sh "$build_type" "$build_feature" );
  print_cmd "${build_cmd[@]}" | tee -a "${log_file}";
  "${build_cmd[@]}" 2>&1 | tee -a "${log_file}";

  exitcode="${PIPESTATUS[0]}"
  if [ "$exitcode" != 0 ]; then
      printf "\n  log file: %s\n\n" "$log_file";
      throw "Failed to build $build_type $build_feature";
  fi
done

#
# 3. build javascript files:
#
if [ -z "$skip_js_bundle" ]; then
pushd -- packages/duckdb-wasm >/dev/null || exit 1;
execute pwd;
export KEEP_DEBUG_LOGS=1;
execute yarn run build:release; 
popd >/dev/null || exit 1;
fi

#endregion core


ls -alh "${target_wasm_files[@]}";
echo "";
echo "build done: +${SECONDS}s"
echo "  log file:  ${log_file}";
echo "";
