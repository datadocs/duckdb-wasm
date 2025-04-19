#!/usr/bin/env bash

#
# Description:
#
#   A bash script used to build all DuckDB WASM files and JavaScript files 
#   before publishing the `duckdb-wasm` package to npm registry.
# 
#   CAVEAT: This script takes a long time to execute, it will build three different WASM variants:
#           MVP, EH and COI. So you can run this script and then go do something else.
#
#           Moreover, this script script is not deisgned for daily development. Please use
#           the script `datadocs_fast_rebuild.sh` if you want to quickly rebuild your changes.
# 
# Usage:   datadocs_release_build_all.sh
# Author:  Liu Yue @hangxingliu
# Version: 2025-04-19
#

# https://github.com/duckdb/duckdb-wasm/blob/main/.github/workflows/main.yml
# $ emsdk list
EMSDK_VERSION=3.1.74;
EMSDK_VERSION_COI=3.1.57;

#
# ================================
#
throw() { printf "${RED}fatal: %s${RESET}\n" "$1" >&2; exit 1; }
print_cmd() { printf "${CYAN}\$${RESET} %s\n" "$*"; }
execute() { print_cmd "$@"; "$@" || throw "Failed to execute '$1'"; }
get_stdout() { print_cmd "$@"; get_stdout_result="$("$@")"; }
COLORMODE="$(tput colors 2>/dev/null || echo '8')";
if [ -n "$COLORMODE" ] && [ "$COLORMODE" -ge 8 ]; then
    RED="\x1b[31m";       GREEN="\x1b[32m";  BLUE="\x1b[34m";
    YELLOW="\x1b[33m";    CYAN="\x1b[36m";   MAGENTA="\x1b[35m";
    BOLD="\x1b[1m";       DIM="\x1b[2m";     ITALIC="\x1b[3m";
    UNDERLINED="\x1b[4m"; REVERSE="\x1b[7m"; HIDDEN="\x1b[8m";
    RESET="\x1b[0m";
fi

# change the current directory to the script directory
pushd "$( dirname -- "${BASH_SOURCE[0]}" )/.." >/dev/null || exit 1;

command -v emsdk >/dev/null || throw "emsdk is not installed!";
command -v yarn  >/dev/null || throw "yarn is not installed!";

SECONDS=0;

execute yarn install;

# Keep downloaded emsdk archive file to avoid re-download them again
execute export EMSDK_KEEP_DOWNLOADS=1;

execute emsdk install "$EMSDK_VERSION";
execute emsdk activate "$EMSDK_VERSION";
execute bash ./scripts/datadocs_fast_rebuild.sh --release --duckdb --skip-js eh mvp;

execute emsdk install "$EMSDK_VERSION_COI";
execute emsdk activate "$EMSDK_VERSION_COI";
execute bash ./scripts/datadocs_fast_rebuild.sh --release --duckdb coi;

execute bash ./scripts/datadocs_generate_git_log.sh;

echo "all done: +${SECONDS}s ($0)"
