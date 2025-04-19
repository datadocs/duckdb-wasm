#!/usr/bin/env bash

TARGET_FILE="packages/duckdb-wasm/git.info";

throw() { printf "fatal: %s\n" "$1" >&2; exit 1; }
print_cmd() { printf "\$ %s\n" "$*"; }
execute() { print_cmd "$@"; "$@" || throw "Failed to execute '$1'"; }
execute_silent() { print_cmd "$@"; "$@" >/dev/null || throw "Failed to execute '$1'"; }
get_stdout() { print_cmd "$@"; get_stdout_result="$("$@")"; }
pushd "$( dirname -- "${BASH_SOURCE[0]}" )/.." >/dev/null || exit 1;

execute rm -f "$TARGET_FILE";
execute git rev-parse --show-toplevel;

commit_hash="$(git rev-parse HEAD)";
commit_name="$(git rev-parse --abbrev-ref HEAD)";

execute_silent pushd submodules/arrow;
commit_hash_arrow="$(git rev-parse HEAD)";
commit_name_arrow="$(git rev-parse --abbrev-ref HEAD)";
execute_silent popd;

execute_silent pushd submodules/duckdb;
commit_hash_duckdb="$(git rev-parse HEAD)";
commit_name_duckdb="$(git rev-parse --abbrev-ref HEAD)";
execute_silent popd;

(
    printf "%-12s %s-%s\n" "duckdb-wasm:" "$commit_hash" "$commit_name";
    printf "%-12s %s-%s\n" "duckdb:" "$commit_hash_duckdb" "$commit_name_duckdb";
    printf "%-12s %s-%s\n" "arrow:" "$commit_hash_arrow" "$commit_name_arrow";
) | tee "$TARGET_FILE";
