#!/usr/bin/env bash

usage() {
  local bin;
  bin="$(basename "${BASH_SOURCE[0]}")";
  echo "";
  echo "  Usage: $bin [--fast] <\$build_machine_host_and_path>";
  echo "";
  echo "  Options:";
  echo "";
  echo "    --fast       rsync 'lib' and 'packages' only, it can be used for incremental sync";
  echo "";
  echo "  Example: $bin hostname:/path/to/duckdb-wasm";
  echo "";
  exit 0;
}

init() {
BASE_DIR=..
[ "$fast_sync" == "1" ] &&
RSYNC_FILES=( lib packages scripts ) ||
RSYNC_FILES=(
	"data"
	"lib" # c++ source code
	"misc"
	"packages"
	"scripts"
	"submodules"
	"tools"

	"Makefile"
	
	"package.json"
	"tsconfig.json"
	"yarn.lock"

	"duckdb.patch"
	"fix.patch"

	"Cargo.lock"
	"Cargo.toml"
)
RSYNC_OPTIONS=(
	-a
	# --xattrs
	--progress
	--iconv=utf-8
	# --delete
	# --dry-run

	--exclude='._*'
	--exclude='.DS_Store'
	--exclude='.github'

	--exclude='node_modules'
	--exclude='examples/*-node'
	--exclude='packages/*/dist'
	--exclude='packages/*/docs'
	--exclude='packages/duckdb-wasm/src/bindings/duckdb*.js'
	--exclude='packages/duckdb-wasm/src/bindings/duckdb*.wasm'
	--exclude='packages/benchmarks'
	# --exclude='packages/duckdb-wasm-*'
	# --exclude='packages/react-duckdb'

	# for remote rsync installed by brew
	# --rsync-path=/usr/local/opt/rsync/bin/rsync
);
# the end of init()
}


throw() { echo -e "${RED}fatal: ${1}${RESET}" >&2; exit 1; }
execute() {
  printf "${BLUE}\$ %s${RESET}\n" "$*";
  "$@" || throw "Failed to execute '$1'";
}
SECONDS=0;
RED="\x1b[31m";
RESET="\x1b[0m";
BLUE="\x1b[34m\e[38;5;87m";

#
# parse args
rsync_target=;
fast_sync=;
parse_args() {
  local arg after_double_dash
  while [ "${#@}" -gt 0 ]; do
    arg="$1"; shift;
    if [ -n "$after_double_dash" ]; then rsync_target="$arg"; continue; fi
    case "$arg" in
      --) after_double_dash=1;;
      -h|--help|help) usage;;
      --fast) fast_sync=1;;
      -*) throw  "Unknown option '$arg'";;
      *) rsync_target="$arg";
    esac
  done
}
parse_args "$@";
test -z "$rsync_target" && usage;
init;

#
# change the current directory to the script directory
pushd "$( dirname -- "${BASH_SOURCE[0]}" )" >/dev/null || exit 1;
execute cd -P "$BASE_DIR";

#
# checking required files
missing_files=();
for file in "${RSYNC_FILES[@]}"; do
  if [ -f "$file" ] || [ -d "$file" ]; then
    continue;
  fi
  missing_files+=("$file");
done
[ "${#missing_files[@]}" -eq 0 ] ||
  throw "There are some files are missing at local: ${missing_files[*]}";

#
# rsync
# force to add a tailing '/'
rsync_target="${rsync_target%/}/";
execute rsync "${RSYNC_OPTIONS[@]}" -- "${RSYNC_FILES[@]}" "$rsync_target";

echo "done: +${SECONDS}s"
#endregion main
