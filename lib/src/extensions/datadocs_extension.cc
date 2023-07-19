#include "duckdb/web/extensions/datadocs_extension.h"

#include "datadocs_extension.hpp"

extern "C" void duckdb_web_datadocs_init(duckdb::DuckDB* db) { db->LoadExtension<duckdb::DatadocsExtension>(); }
