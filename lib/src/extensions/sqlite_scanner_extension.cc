#include "duckdb/web/extensions/sqlite_scanner_extension.h"

#include "sqlite_scanner_extension.hpp"

extern "C" void duckdb_web_sqlite_scanner_init(duckdb::DuckDB* db) {
    db->LoadExtension<SqliteScannerExtension>();
}
