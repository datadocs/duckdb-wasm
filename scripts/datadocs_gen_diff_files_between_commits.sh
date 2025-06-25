#!/usr/bin/env bash

#
# Description:
#
#   This script dump info of each commit between two commits into the `git-diff-logs` directory
#     for easily searching historical changes.
#
# Author:  Liu Yue @hangxingliu
# Version: 2025-06-23
#

TARGET_DIR="git-diff-logs";

# https://github.com/duckdb/duckdb/compare/ingest-v1.2.2-base...datadocs:duckdb-wasm:master
# datadocs-v1.2-base
# duckdb-wasm-shell: bump dependencies
first_commit=${1:-'de7382ee418b5cac6b268124f5daa83a80fdf8e7'}
# Add `builtin_httpfs` SQL option to allow keep using current in-build httpfs
last_commit=${2:-'dbe2d00ce519720919e9564443396c5b5c2ad20c'}

throw() { printf "fatal: %s\n" "$1" >&2; exit 1; }
print_cmd() { printf "\$ %s\n" "$*"; }
execute() { print_cmd "$@"; "$@" || throw "Failed to execute '$1'"; }
get_stdout() { print_cmd "$@"; get_stdout_result="$("$@")"; }

# change the current directory to the project directory
pushd "$( dirname -- "${BASH_SOURCE[0]}" )/.." >/dev/null || exit 1;
execute mkdir -p "$TARGET_DIR";

# usage: <commit_form> <commit_to> <base-dir>
gen_diff_files() {
    git_cmd=( git rev-list --reverse "${1}..${2}" );
    get_stdout "${git_cmd[@]}";

    commit_hash=();
    count=0;
    while read -r line; do
        [ -z "$line" ] && continue;
        commit_hash+=( "$line" );
        count=$((count+1));
    done <<< "${get_stdout_result}";

    echo "";
    echo "found ${count} commits";
    echo "";

    commit_index=0;
    while [[ "$commit_index" -lt "$count" ]]; do
        commit_ptr="${commit_hash[$commit_index]}";
        file_name="${3}/${commit_index}-${commit_ptr}.patch";

        commit_index=$((commit_index+1));
        git_cmd=( git show --stat -p -n1 "${commit_ptr}");
        print_cmd "${git_cmd[@]}" "> ${file_name}";
        "${git_cmd[@]}" > "${file_name}" || throw "failed to run 'git format-patch'";
    done
}

gen_diff_files "$first_commit" "$last_commit" "$TARGET_DIR";

