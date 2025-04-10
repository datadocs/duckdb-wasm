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
	# fast sync
	RSYNC_FILES=( 
		lib 
		patches 
		packages 
		scripts
	) ||
	# normal sync
	RSYNC_FILES=(
		"data"
		"lib" # c++ source code
		"misc"
		"packages"
		"patches"
		"scripts"
		"submodules"
		"tools"

		"Cargo.lock"
		"Cargo.toml"
		"docker-compose.yml"
		"extension_config_wasm.cmake"
		"fix.patch"
		"Makefile"
		"package.json"
		README.md
		"tsconfig.json"

		"yarn.lock"
	);
	RSYNC_EXCLUDE=(
		'node_modules'
		'examples/*-node'
		'packages/*/dist'
		'packages/*/docs'
		'packages/duckdb-wasm/src/bindings/duckdb*.js'
		'packages/duckdb-wasm/src/bindings/duckdb*.wasm'
		'packages/benchmarks'
		# 'packages/duckdb-wasm-*'
		# 'packages/react-duckdb'
	);
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
		
		# for remote rsync installed by brew
		# --rsync-path=/usr/local/opt/rsync/bin/rsync
	);
	for glob in "${RSYNC_EXCLUDE[@]}"; do
		RSYNC_OPTIONS+=( --exclude="$glob" );
	done
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
