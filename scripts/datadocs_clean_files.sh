#!/usr/bin/env bash

throw() { echo -e "fatal: $1" >&2; exit 1; }
execute() { echo "$ $*"; "$@" || throw "Failed to execute '$1'"; }

pushd "$( dirname -- "${BASH_SOURCE[0]}" )/.." >/dev/null || exit 1;

find_reject_files() {
    local cmd;
    cmd=( git status --untracked-files=all --short );
    echo "$ ${cmd[*]}";
    files="$("${cmd[@]}" | awk '/^\?\?/ && /\.rej$/ {print $2}')";
}

if [ -d "submodules/duckdb" ]; then
    execute pushd "submodules/duckdb";
    find_reject_files;
    while read -r file; do [ -n "$file" ] && [ -f "$file" ] && execute rm "$file";
    done <<< "${files}";
    execute find . -type f -iname '*.rej.orig' -delete;
    execute popd;
fi
if [ -d "submodules/arrow" ]; then
    execute pushd "submodules/arrow";
    find_reject_files;
    while read -r file; do [ -n "$file" ] && [ -f "$file" ] && execute rm "$file";
    done <<< "${files}";
    execute find . -type f -iname '*.rej.orig' -delete;
    execute popd;
fi

