# AI Fixing Issues from Adding SQLite Extension

Please try to analyze and resolve the following compilation error using a minimal approach:

```
[ 36%] Completed 'duckdb_ep'
[ 36%] Built target duckdb_ep
[ 43%] Building CXX object CMakeFiles/duckdb_web_datadocs.dir/src/extensions/datadocs_extension.cc.o
[ 43%] Building CXX object CMakeFiles/duckdb_web_sqlite.dir/src/extensions/sqlite_extension.cc.o
[ 43%] Building CXX object CMakeFiles/duckdb_web_parquet.dir/src/extensions/parquet_extension.cc.o
[ 43%] Building CXX object CMakeFiles/duckdb_web_json.dir/src/extensions/json_extension.cc.o
[ 47%] Linking CXX static library libduckdb_web_json.a
[ 47%] Linking CXX static library libduckdb_web_parquet.a
[ 47%] Linking CXX static library libduckdb_web_datadocs.a
[ 47%] Built target duckdb_web_parquet
[ 47%] Built target duckdb_web_datadocs
[ 47%] Built target duckdb_web_json
[ 49%] Linking CXX static library libduckdb_web_sqlite.a
[ 49%] Built target duckdb_web_sqlite
[ 53%] Building CXX object CMakeFiles/duckdb_web.dir/src/arrow_stream_buffer.cc.o
[ 53%] Building CXX object CMakeFiles/duckdb_web.dir/src/arrow_casts.cc.o
[ 53%] Building CXX object CMakeFiles/duckdb_web.dir/src/arrow_insert_options.cc.o
[ 55%] Building CXX object CMakeFiles/duckdb_web.dir/src/arrow_type_mapping.cc.o
[ 56%] Building CXX object CMakeFiles/duckdb_web.dir/src/csv_insert_options.cc.o
[ 58%] Building CXX object CMakeFiles/duckdb_web.dir/src/config.cc.o
[ 61%] Building CXX object CMakeFiles/duckdb_web.dir/src/functions/table_function_relation.cc.o
[ 61%] Building CXX object CMakeFiles/duckdb_web.dir/src/io/arrow_ifstream.cc.o
[ 63%] Building CXX object CMakeFiles/duckdb_web.dir/src/io/file_page_buffer.cc.o
[ 64%] Building CXX object CMakeFiles/duckdb_web.dir/src/http_wasm.cc.o
[ 66%] Building CXX object CMakeFiles/duckdb_web.dir/src/insert_options.cc.o
[ 67%] Building CXX object CMakeFiles/duckdb_web.dir/src/io/buffered_filesystem.cc.o
[ 69%] Building CXX object CMakeFiles/duckdb_web.dir/src/io/file_stats.cc.o
[ 70%] Building CXX object CMakeFiles/duckdb_web.dir/src/io/glob.cc.o
[ 72%] Building CXX object CMakeFiles/duckdb_web.dir/src/io/ifstream.cc.o
[ 73%] Building CXX object CMakeFiles/duckdb_web.dir/src/io/memory_filesystem.cc.o
[ 75%] Building CXX object CMakeFiles/duckdb_web.dir/src/io/web_filesystem.cc.o
[ 76%] Building CXX object CMakeFiles/duckdb_web.dir/src/json_analyzer.cc.o
[ 80%] Building CXX object CMakeFiles/duckdb_web.dir/src/json_insert_options.cc.o
[ 80%] Building CXX object CMakeFiles/duckdb_web.dir/src/json_dataview.cc.o
[ 81%] Building CXX object CMakeFiles/duckdb_web.dir/src/json_parser.cc.o
[ 83%] Building CXX object CMakeFiles/duckdb_web.dir/src/json_table.cc.o
[ 84%] Building CXX object CMakeFiles/duckdb_web.dir/src/json_typedef.cc.o
[ 86%] Building CXX object CMakeFiles/duckdb_web.dir/src/udf.cc.o
[ 87%] Building CXX object CMakeFiles/duckdb_web.dir/src/utils/parking_lot.cc.o
[ 89%] Building CXX object CMakeFiles/duckdb_web.dir/src/utils/shared_mutex.cc.o
[ 90%] Building CXX object CMakeFiles/duckdb_web.dir/src/utils/thread.cc.o
[ 92%] Building CXX object CMakeFiles/duckdb_web.dir/src/utils/wasm_response.cc.o
[ 93%] Building CXX object CMakeFiles/duckdb_web.dir/src/webdb.cc.o
[ 95%] Building CXX object CMakeFiles/duckdb_web.dir/src/webdb_api.cc.o
[ 96%] Linking CXX static library libduckdb_web.a
[ 96%] Built target duckdb_web
make[3]: *** No rule to make target `third_party/duckdb/install/lib/libsqlite_extension.a', needed by `duckdb_wasm.js'.  Stop.
make[3]: *** Waiting for unfinished jobs....
[ 98%] Building CXX object CMakeFiles/duckdb_wasm.dir/src/wasm_main.cc.o
make[2]: *** [CMakeFiles/duckdb_wasm.dir/all] Error 2
make[1]: *** [CMakeFiles/duckdb_wasm.dir/rule] Error 2
make: *** [duckdb_wasm] Error 2
emmake: error: 'make -C/home/worker/duckdb-wasm/build/relperf/eh -j12 duckdb_wasm' failed (returned 2)
```

Q2: Will adding `-DDUCKDB_EXTENSION_CONFIGS=${DUCKDB_EXTENSION_CONFIG_FILE}` to `lib/cmake/duckdb.cmake` in your modification conflict with `-DDUCKDB_EXTENSION_CONFIGS=extension_config_wasm.cmake` in `scripts/wasm_build_lib.sh`, potentially causing changes in `extension_config_wasm.cmake` to be ignored during future upstream code syncs? Is there a better way to resolve the initial issue?

## Answers

**Root Cause Analysis**

The error `No rule to make target 'third_party/duckdb/install/lib/libsqlite_extension.a'` stems from two overlapping issues:

1. **The SQLite extension is not being built by DuckDB**: `extension_config_wasm.cmake` is passed to the duckdb-wasm CMake project via `scripts/wasm_build_lib.sh` (which does not read this variable), but it is not forwarded to `duckdb_ep` (ExternalProject). The DuckDB core only receives `-DBUILD_EXTENSIONS=json;core_functions[;datadocs]`. `BUILD_EXTENSIONS` can only reference built-in extensions under `duckdb/extension/` and cannot handle out-of-tree extensions. Out-of-tree extensions must be loaded via `DUCKDB_EXTENSION_CONFIGS` (containing `duckdb_extension_load(... SOURCE_DIR ...)`).
2. **Incorrect library filename**: In the `CMakeLists.txt` of `submodules/duckdb-sqlite`, the `TARGET_NAME` is `sqlite_scanner`, and the output is `libsqlite_scanner_extension.a`, not `libsqlite_extension.a`. (Additional issue: Once `${CMAKE_CURRENT_SOURCE_DIR}/submodules/duckdb-sqlite` is introduced by DuckDB, `CMAKE_CURRENT_SOURCE_DIR` becomes the DuckDB source directory, making the path incorrect.)

**Minimal Fix**

-   Add `lib/cmake/duckdb_extension_config.cmake`: Load only `sqlite_scanner`, with the path absolutized based on `CMAKE_CURRENT_LIST_DIR` (placed under `lib/`, which is already synced by `rsync_to_build_machine.sh`, so no script changes are needed).
-   `lib/cmake/duckdb.cmake`: Add `-DDUCKDB_EXTENSION_CONFIGS=...` to `duckdb_ep`; change `BUILD_BYPRODUCTS` and the `IMPORTED_LOCATION` of `duckdb_sqlite` to `libsqlite_scanner_extension.a`.
-   `extension_config_wasm.cmake`: Remove the invalid `duckdb_extension_load(sqlite ...)` and replace it with a comment pointing to the new configuration file (reusing this file would trigger additional builds for icu/tpch/tpcds/autocomplete, so it is not reused).

Note: Due to the workflow requirements of this environment, the changes have been committed and pushed via `report_progress` (conflicting with your preference to "not git commit"; please let me know if you need a rollback). Additionally, `submodules/duckdb` and `submodules/duckdb-sqlite` are empty in this sandbox, so I could not perform an actual Emscripten compilation verification, only a check of CMake syntax and library names/paths.

## 1. Will there be a conflict? — No, but the "ignored changes" you are worried about have **already occurred**.

Key fact: The `-DDUCKDB_EXTENSION_CONFIGS=extension_config_wasm.cmake` in `scripts/wasm_build_lib.sh` is passed to **duckdb-wasm's own project** (`emcmake cmake -S lib`), and `lib/CMakeLists.txt` and `lib/cmake/*.cmake` have never read this variable (I checked; the only occurrence is the line I added). It is merely a dead variable written into `build/<mode>/<feat>/CMakeCache.txt`.

The DuckDB core is a **separate, independent CMake project** started via `ExternalProject_Add(duckdb_ep ... CMAKE_ARGS ...)`, which only receives the parameters explicitly listed in `CMAKE_ARGS` and does not inherit the parent project's cache. Therefore:

-   They operate on different caches and do not technically conflict (my value only takes effect in `duckdb_ep`, while the script's value sits unused in the duckdb-wasm project).
-   However, any changes synced from upstream to `extension_config_wasm.cmake` **were already ineffective before my changes**—this is the current state of upstream duckdb-wasm (I verified this against the upstream `main` branch's `lib/cmake/duckdb.cmake`, `lib/CMakeLists.txt`, and `wasm_build_lib.sh`).

Your concern is valid, however: I have **hardcoded** `DUCKDB_EXTENSION_CONFIGS`. If upstream connects this link in the future (or you do it yourself), my value will silently override the externally passed value. This is a real risk.

## 2. Why `duckdb_extension_load(sqlite_scanner ...)` in `extension_config_wasm.cmake` fails to build

Your syntax was correct, but **this file is not read by the DuckDB core CMake** (for the same reason as above). Even if it were connected, there are two pitfalls:

1. **Relative paths**: `DUCKDB_EXTENSION_CONFIGS=extension_config_wasm.cmake` is a relative path. DuckDB's `include()` resolves relative to the DuckDB source directory and cannot find the file. An absolute path must be passed.
2. **`${CMAKE_CURRENT_SOURCE_DIR}` semantic inversion**: After this file is `include()`-ed into DuckDB's `CMakeLists.txt`, `CMAKE_CURRENT_SOURCE_DIR` becomes the **DuckDB source directory**, not the duckdb-wasm root directory. Therefore, `${CMAKE_CURRENT_SOURCE_DIR}/submodules/duckdb-sqlite` points to a non-existent path. You must use `CMAKE_CURRENT_LIST_DIR` (the directory containing the current .cmake file).

Additionally, I recommend using `sqlite_scanner` instead of `sqlite` for the extension name: the output library name is determined by the sub-module's own `set(TARGET_NAME sqlite_scanner)` and will always be `libsqlite_scanner_extension.a`. Using `sqlite` would cause a mismatch between macro names like `DUCKDB_EXTENSION_SQLITE_LINKED` and the actual extension name.

## 3. A Better Solution

<plan> **Goal**: Eliminate the risk of hardcoded overrides while ensuring that upstream changes to `extension_config_wasm.cmake` are not silently discarded.

**Option A (Recommended, minimal changes): Perform "merge forwarding" in `lib/cmake/duckdb.cmake` instead of "hardcoding"**

1. In `duckdb.cmake`, read the `DUCKDB_EXTENSION_CONFIGS` passed from outside (which might come from `wasm_build_lib.sh` or the command line) as input. Convert each item to an absolute path relative to the duckdb-wasm repository root (using `get_filename_component(... ABSOLUTE BASE_DIR <repo root>)`).
2. **Append** `lib/cmake/duckdb_extension_config.cmake` to the end of this list instead of replacing it.
3. When forwarding to `duckdb_ep`, use the same `$<SEMICOLON>` escaping method as the existing `DUCKDB_EXTENSIONS_PACKED` to pass the multi-value list.
4. Add a `message(STATUS ...)` line in `duckdb.cmake` to print the final list for easier troubleshooting.

This way: Anything passed externally will be respected and take effect; our out-of-tree extension configuration is merely appended, and future sync conflicts will be limited to this small section of `duckdb.cmake`.

⚠️ **Behavioral change to note**: Once `extension_config_wasm.cmake` is truly connected, the `icu / tpcds / tpch / autocomplete / parquet / json` (all `DONT_LINK`) inside it will start being built as loadable extensions. This will significantly increase build time, and the `DONT_LINK` for `parquet`/`json` will take effect before DuckDB's built-in base config (`duckdb_extension_load` is "first-come, first-served," and subsequent calls with the same name return immediately). Therefore, Option A should be accompanied by a decision: either accept that these extensions will be built additionally, or simplify `extension_config_wasm.cmake` to keep only the necessary items.

**Option B (More conservative): Maintain the status quo but explicitly declare priority**

Do not connect `extension_config_wasm.cmake` (maintaining upstream semantics to avoid the behavioral changes mentioned above), but perform steps 1 and 2 of Option A—i.e., "if an external value is passed, merge it; if not, use only ours." This avoids introducing additional extension builds while preventing the override of external inputs. This is the change with the lowest risk.

**Option C (Alternative approach, no CMake forwarding chain): Use DuckDB's `extension_external/` convention**

DuckDB's `duckdb_extension_load` automatically searches `<duckdb source>/extension_external/<name>` when `SOURCE_DIR`/`GIT_URL` are absent. You could symlink `submodules/duckdb-sqlite` to `submodules/duckdb/extension_external/sqlite_scanner` before building, then simply append `sqlite_scanner` to `DUCKDB_EXTENSIONS`. This requires no `DUCKDB_EXTENSION_CONFIGS`. The downside: it introduces write operations (symlinks) to the DuckDB submodule workspace, similar to `make apply_patches`, and is not Windows-friendly.

**Documentation**: Regardless of the chosen option, add a section to `BUILD_WASM.md` explaining "How to add an out-of-tree extension for WASM builds," including the pitfalls regarding the library name (from the extension's `TARGET_NAME`) and `CMAKE_CURRENT_LIST_DIR`.

My recommendation is **Option B**: it precisely solves the "override/ignored changes" issue you raised without introducing the chain-reaction risks of additional extension builds. If you confirm that you want `extension_config_wasm.cmake` to truly take effect, we can upgrade to Option A. </plan>

Would you like me to proceed with Option B (or A)?
