#!/usr/bin/env bash

#
# Description:
#
#   A bash script used to clean up patch-related files (*.rej, *.rej.orig) in git sub modules
#   --reset: execute `git reset --hard` on each git sub modules 
#
# Usage:   datadocs_clean_files.sh [--reset|--force]
# Author:  Liu Yue @hangxingliu
# Version: 2025-04-19
git_sub_modules=(
	submodules/duckdb
	submodules/arrow
);


usage() {
  local bin;
  bin="$(basename "${BASH_SOURCE[0]}")";
  echo "";
  echo "  Usage: $bin [--reset|--force]";
  echo "";
  exit 0;
}
throw() { echo -e "fatal: $1" >&2; exit 1; }
print_cmd() { printf "\$ %s\n" "$*"; }
execute() { print_cmd "$@"; "$@" || throw "Failed to execute '$1'"; }
execute_silent() { print_cmd "$@"; "$@" >/dev/null || throw "Failed to execute '$1'"; }
get_stdout() { print_cmd "$@"; get_stdout_result="$("$@")"; }

git_hard_reset=false;
has_yes=false;
parse_args() {
  local arg after_double_dash
  while [ "${#@}" -gt 0 ]; do
	arg="$1"; shift;
	if [ -n "$after_double_dash" ]; then throw "Unknown option '$arg'"; fi
	case "$arg" in
	  --) after_double_dash=1;;
	  -h|--help|help) usage;;
	  -y|--yes) has_yes=true;;
	  --reset|--force|-f) git_hard_reset=true;;
	  *) throw  "Unknown option '$arg'";;
	esac
  done
}
confirm() {
  "$has_yes" && return 0;
  [ -n "$1" ] && printf "? %s (yes/NO) > " "$1" >&2;
  read -r yesno;
  if [[ "$yesno" == "y"* ]] || [[ "$yesno" == "Y"* ]]; then return 0;
  else return 1;
  fi
}
parse_args "$@";


execute_silent pushd "$( dirname -- "${BASH_SOURCE[0]}" )/..";
for sub_module_dir in "${git_sub_modules[@]}"; do
	[ -d "$sub_module_dir" ] || continue;

	execute_silent pushd "$sub_module_dir";
	if $git_hard_reset; then
		execute git status --untracked-files=all --short;

		print_cmd git reset --hard HEAD;
		confirm "all changes in ${sub_module_dir} will be dropped" &&
			execute git reset --hard HEAD;
	else
		get_stdout git status --untracked-files=all --short;
		files="$(echo "$get_stdout_result" | awk '/^\?\?/ && /\.rej$/ {print $2}')";
		while read -r file; 
		do [ -n "$file" ] && execute rm -f "${file}" "${file}.orig";
		done <<< "${files}";
	fi
	execute_silent popd;
done
