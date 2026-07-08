################################################################################
# DuckDB-Wasm extension base config
################################################################################
#

duckdb_extension_load(json DONT_LINK)
duckdb_extension_load(parquet DONT_LINK)
duckdb_extension_load(autocomplete DONT_LINK)

duckdb_extension_load(icu DONT_LINK)
duckdb_extension_load(tpcds DONT_LINK)
duckdb_extension_load(tpch DONT_LINK)

#duckdb_extension_load(httpfs DONT_LINK)

# sqlite_scanner: statically compiled in (no DONT_LINK) so it auto-loads at
# startup without needing LOAD or a home directory on the filesystem.
duckdb_extension_load(sqlite_scanner
    SOURCE_DIR /Users/David.Litwin/Desktop/Dev/duckdb-wasm/submodules/sqlite_scanner
)
