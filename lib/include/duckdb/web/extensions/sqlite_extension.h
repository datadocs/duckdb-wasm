#ifndef INCLUDE_DUCKDB_WEB_EXTENSIONS_SQLITE_SCANNER_EXTENSION_H_
#define INCLUDE_DUCKDB_WEB_EXTENSIONS_SQLITE_SCANNER_EXTENSION_H_

#include "duckdb/main/database.hpp"

extern "C" void duckdb_web_sqlite_init(duckdb::DuckDB* db);

#endif
