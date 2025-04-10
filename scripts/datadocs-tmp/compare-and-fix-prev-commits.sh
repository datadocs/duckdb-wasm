#!/usr/bin/env bash

throw() { printf "fatal: %s\n" "$1" >&2; exit 1; }
print_cmd() { printf "\$ %s\n" "$*"; }
execute() { print_cmd "$@"; "$@" || throw "Failed to execute '$1'"; }

# change the current directory to the script directory
pushd "$( dirname -- "${BASH_SOURCE[0]}" )" >/dev/null || exit 1;

execute mkdir -p git-diff-files/a;
execute mkdir -p git-diff-files/b;

# https://github.com/duckdb/duckdb-wasm/compare/main...datadocs:duckdb-wasm:master
# (Jun 14 2023)  init build wasm for datadocs      
prev_merge1_from=f9636fbc876f17ccf4e199dcd28a108d8c9b9e54
# (Feb 05 2024)  Update function ingest_get_schema
prev_merge1_to=721cb14a8aff8928f75b54298d4db1eaf2993c26

# (Feb 16 2024)  init build wasm for datadocs
prev_merge2_from=1963780b044f0b29550ed261d6293a8e62a200bb
# (Feb 16 2024)  Update function ingest_get_schema
prev_merge2_to=1d6f628df5397970f64d20d14456e0cf4e5407cf

# usage: <commit_form> <commit_to> <base-dir>
gen_diff_files() {
    # from latest to the oldest
    commit_hash=();
    commit_ptr="$2";
    ciruit_breaker=100;
    count=0;

    echo "";
    echo "scanning commits in ${1}..${2}";
    echo "";
    while true; do
        commit_hash+=( "$commit_ptr" );
        count=$((count+1));
        [[ "$commit_ptr" == "${1}" ]] && break;

        ciruit_breaker=$((ciruit_breaker - 1));
        [[ "$ciruit_breaker" -gt 0 ]] || throw "circuit break is open";

        expr="${commit_ptr}^"
        commit_ptr="$(git rev-parse "${expr}")";
        [[ -n "$commit_ptr" ]] || throw "failed to get the commit of '$expr'";
    done

    commit_index=0;
    while [[ "$commit_index" -lt "$count" ]]; do
        commit_ptr="${commit_hash[$((count - commit_index - 1))]}";
        file_name="${3}/${commit_index}.patch";

        commit_index=$((commit_index+1));
        (
            echo "${commit_ptr}";
            git log --format='%h %s' -n 1 "${commit_ptr}"
        )> "${file_name}";
        git_cmd=( git diff "${commit_ptr}^..${commit_ptr}" );
        print_cmd "${git_cmd[@]}" "> ${file_name}";
        "${git_cmd[@]}" >> "${file_name}" || throw "failed to run 'git diff'";
    done
}

gen_diff_files "$prev_merge1_from" "$prev_merge1_to" "git-diff-files/a"
gen_diff_files "$prev_merge2_from" "$prev_merge2_to" "git-diff-files/b"
