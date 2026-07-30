################################################################################
# Extension config for the DuckDB core build (duckdb_ep)
################################################################################
#
# This file is passed to the DuckDB core build through `DUCKDB_EXTENSION_CONFIGS`.
# It is required for out-of-tree extensions, because the plain `BUILD_EXTENSIONS`
# variable can only reference extensions that live inside the DuckDB repository.
#
# NOTE: the target/library name of the sqlite extension is `sqlite_scanner_extension`,
# it is defined in `submodules/duckdb-sqlite/CMakeLists.txt`.

get_filename_component(DUCKDB_WASM_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

duckdb_extension_load(sqlite_scanner
  SOURCE_DIR ${DUCKDB_WASM_ROOT_DIR}/submodules/duckdb-sqlite)
