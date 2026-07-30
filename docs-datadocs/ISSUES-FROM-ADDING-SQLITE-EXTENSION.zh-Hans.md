# AI Fixing Issues from Adding SQLite Extension

请尝试分析和最小化方式解决下面这个编译错误:

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



Q2: 请问你上面这个修改中在 lib/cmake/duckdb.cmake 中加入的 -DDUCKDB_EXTENSION_CONFIGS=${DUCKDB_EXTENSION_CONFIG_FILE} 是否会和 scripts/wasm_build_lib.sh 里面的 -DDUCKDB_EXTENSION_CONFIGS=extension_config_wasm.cmake 相冲突而导致后续上游代码 sync 的时候, 在 extension_config_wasm.cmake 中的变动被忽略掉. 是否可以通过更好的方式去解决初始问题.



## Answers

**根因分析**

报错 `No rule to make target 'third_party/duckdb/install/lib/libsqlite_extension.a'` 有两个叠加的问题：

1. **sqlite 扩展根本没有被 duckdb 构建**：`extension_config_wasm.cmake` 只是通过 `scripts/wasm_build_lib.sh` 传给了 duckdb-wasm 自己的 CMake 工程（该工程完全不读这个变量），并没有被转发给 `duckdb_ep`（ExternalProject）。duckdb core 只收到 `-DBUILD_EXTENSIONS=json;core_functions[;datadocs]`，而 `BUILD_EXTENSIONS` 只能引用 `duckdb/extension/` 下的内置扩展，无法处理 out-of-tree 扩展。out-of-tree 扩展必须通过 `DUCKDB_EXTENSION_CONFIGS`（内含 `duckdb_extension_load(... SOURCE_DIR ...)`）加载。
2. **库文件名写错**：`submodules/duckdb-sqlite` 的 `CMakeLists.txt` 中 `TARGET_NAME` 是 `sqlite_scanner`，产物是 `libsqlite_scanner_extension.a`，而不是 `libsqlite_extension.a`。 （附带问题：原来那行 `${CMAKE_CURRENT_SOURCE_DIR}/submodules/duckdb-sqlite` 一旦被 duckdb 引入，`CMAKE_CURRENT_SOURCE_DIR` 会是 duckdb 源码目录，路径也是错的。）

**最小修复**

- 新增 `lib/cmake/duckdb_extension_config.cmake`：只加载 `sqlite_scanner`，路径基于 `CMAKE_CURRENT_LIST_DIR` 绝对化（放在 `lib/` 下，`rsync_to_build_machine.sh` 已同步该目录，无需改脚本）。
- `lib/cmake/duckdb.cmake`：向 `duckdb_ep` 增加 `-DDUCKDB_EXTENSION_CONFIGS=...`；把 `BUILD_BYPRODUCTS` 和 `duckdb_sqlite` 的 `IMPORTED_LOCATION` 改为 `libsqlite_scanner_extension.a`。
- `extension_config_wasm.cmake`：移除无效的 `duckdb_extension_load(sqlite ...)`，改为注释指向新配置文件（沿用该文件会额外构建 icu/tpch/tpcds/autocomplete，故不复用）。

注意：由于本环境的工作流要求，改动已被 `report_progress` 提交并推送（与你“不要 git 提交”的偏好冲突，如需回退请告知）。另外 `submodules/duckdb`、`submodules/duckdb-sqlite` 在本沙箱里是空的，无法实际跑一遍 emscripten 编译验证，只做了 CMake 语法与库名/路径的核对。



## 1. 会不会冲突？—— 不会冲突，但你担心的“变动被忽略”其实**早就已经发生了**

关键事实：`scripts/wasm_build_lib.sh` 里的 `-DDUCKDB_EXTENSION_CONFIGS=extension_config_wasm.cmake` 是传给 **duckdb-wasm 自己的工程**（`emcmake cmake -S lib`），而 `lib/CMakeLists.txt` 和 `lib/cmake/*.cmake` 从来没有读过这个变量（我 grep 过，唯一出现处就是我新加的那行）。它只是被写进了 `build/<mode>/<feat>/CMakeCache.txt` 里的一个死变量。

而 duckdb core 是通过 `ExternalProject_Add(duckdb_ep ... CMAKE_ARGS ...)` 启动的**另一个独立 CMake 工程**，只会收到 `CMAKE_ARGS` 里显式列出的参数，不会继承父工程的 cache。所以：

- 两者作用在不同的 cache 上，技术上不冲突（我的值只在 duckdb_ep 里生效，脚本的值在 duckdb-wasm 工程里躺着没人用）。
- 但 `extension_config_wasm.cmake` 从上游 sync 过来的任何改动，**在我改之前就已经完全不生效了**——这是上游 duckdb-wasm 本身的现状（我拉了 upstream `main` 的 `lib/cmake/duckdb.cmake`、`lib/CMakeLists.txt`、`wasm_build_lib.sh` 核对，上游同样是死变量）。

不过你的顾虑是合理的：我现在是**硬编码**了 `DUCKDB_EXTENSION_CONFIGS`，如果将来上游把这条链路接通了（或者你自己接通），我的值会静默覆盖掉外部传入的值。这是真实的隐患。

## 2. 为什么 `duckdb_extension_load(sqlite_scanner ...)` 写在 `extension_config_wasm.cmake` 里编不出来

你没写错语法，是**这个文件根本没被 duckdb core 的 CMake 读到**（原因同上）。即使把它接通，原来那行还有两个会踩的坑：

1. **相对路径**：`DUCKDB_EXTENSION_CONFIGS=extension_config_wasm.cmake` 是相对路径，duckdb 的 `include()` 会相对 duckdb 源码目录解析，找不到文件。必须传绝对路径。
2. **`${CMAKE_CURRENT_SOURCE_DIR}` 语义翻转**：该文件被 `include()` 进 duckdb 的 `CMakeLists.txt` 后，`CMAKE_CURRENT_SOURCE_DIR` 是 **duckdb 的源码目录**，不是 duckdb-wasm 根目录，所以 `${CMAKE_CURRENT_SOURCE_DIR}/submodules/duckdb-sqlite` 指向了一个不存在的路径。要用 `CMAKE_CURRENT_LIST_DIR`（当前 .cmake 文件所在目录）。

另外扩展名建议用 `sqlite_scanner` 而不是 `sqlite`：产物库名由子模块自己的 `set(TARGET_NAME sqlite_scanner)` 决定，永远是 `libsqlite_scanner_extension.a`；用 `sqlite` 只会让 `DUCKDB_EXTENSION_SQLITE_LINKED` 之类的宏名和实际扩展名对不上。

## 3. 更好的解法

<plan> **目标**：消除硬编码覆盖风险，同时让 `extension_config_wasm.cmake` 的上游变动不再被静默丢弃。

**方案 A（推荐，改动仍然很小）：在 `lib/cmake/duckdb.cmake` 里做「合并转发」而不是「硬编码」**

1. 在 `duckdb.cmake` 中把外部传入的 `DUCKDB_EXTENSION_CONFIGS`（可能来自 `wasm_build_lib.sh`，也可能来自命令行）作为输入读入，对其中每一项做「相对路径 → 相对 duckdb-wasm 仓库根目录的绝对路径」转换（用 `get_filename_component(... ABSOLUTE BASE_DIR <repo root>)`）。
2. 把 `lib/cmake/duckdb_extension_config.cmake` **追加**到这个列表尾部，而不是替换它。
3. 转发给 `duckdb_ep` 时，用现有 `DUCKDB_EXTENSIONS_PACKED` 同款的 `$<SEMICOLON>` 转义方式传多值列表。
4. 在 `duckdb.cmake` 里加一行 `message(STATUS ...)` 打印最终列表，便于排查。

这样：外部传什么都会被尊重并真正生效，我们的 out-of-tree 扩展配置只是追加，未来 sync 时冲突面只在 `duckdb.cmake` 的这一小段。

⚠️ 需要注意的**行为变更**：一旦真的把 `extension_config_wasm.cmake` 接通，里面的 `icu / tpcds / tpch / autocomplete / parquet / json`（都是 `DONT_LINK`）会开始被当作 loadable extension 构建，构建时间会明显变长，且 `parquet`/`json` 的 `DONT_LINK` 会先于 duckdb 自带的 base config 生效（`duckdb_extension_load` 是「先到先得」，后续同名调用直接 return）。所以方案 A 应当配套确认：要么接受这些扩展被额外构建，要么先把 `extension_config_wasm.cmake` 精简成只保留真正需要的项。

**方案 B（更保守）：保持现状但显式声明优先级**

不去接通 `extension_config_wasm.cmake`（维持上游语义，避免上面的行为变更），只把方案 A 的第 1、2 步做掉——即「若外部传了值就合并，没传就只用我们的」。这样不会引入新的扩展构建，同时也不会覆盖外部输入。这是改动最小、风险最低的一档。

**方案 C（另一种思路，不动 CMake 转发链）：改用 duckdb 的 `extension_external/` 约定**

duckdb 的 `duckdb_extension_load` 在没有 `SOURCE_DIR`/`GIT_URL` 时，会自动查找 `<duckdb 源码>/extension_external/<name>`。可以在构建前把 `submodules/duckdb-sqlite` 软链到 `submodules/duckdb/extension_external/sqlite_scanner`，然后只需在 `DUCKDB_EXTENSIONS` 里追加 `sqlite_scanner` 即可，完全不需要 `DUCKDB_EXTENSION_CONFIGS`。缺点：引入了对 duckdb 子模块工作区的写操作（软链），和现有 `make apply_patches` 一样属于「污染子模块」的做法，且 Windows 上不友好。

**文档配套**：无论选哪个方案，都在 `BUILD_WASM.md` 中补一节（中文）说明「如何为 WASM 构建接入一个 out-of-tree 扩展」，包含库名来自扩展自身 `TARGET_NAME`、以及 `CMAKE_CURRENT_LIST_DIR` 这两个坑。

我的建议是**方案 B**：它精确解决了你提出的「覆盖 / 变动被忽略」问题，又不引入额外扩展构建带来的连锁风险。如果你确认希望 `extension_config_wasm.cmake` 真正生效，再升级到方案 A。 </plan>

需要我按方案 B（或 A）实际改一下吗？

我核对了三处引用点后回答。

## 1. 会不会冲突？—— 不会冲突，但你担心的“变动被忽略”其实**早就已经发生了**

关键事实：`scripts/wasm_build_lib.sh` 里的 `-DDUCKDB_EXTENSION_CONFIGS=extension_config_wasm.cmake` 是传给 **duckdb-wasm 自己的工程**（`emcmake cmake -S lib`），而 `lib/CMakeLists.txt` 和 `lib/cmake/*.cmake` 从来没有读过这个变量（我 grep 过，唯一出现处就是我新加的那行）。它只是被写进了 `build/<mode>/<feat>/CMakeCache.txt` 里的一个死变量。

而 duckdb core 是通过 `ExternalProject_Add(duckdb_ep ... CMAKE_ARGS ...)` 启动的**另一个独立 CMake 工程**，只会收到 `CMAKE_ARGS` 里显式列出的参数，不会继承父工程的 cache。所以：

- 两者作用在不同的 cache 上，技术上不冲突（我的值只在 duckdb_ep 里生效，脚本的值在 duckdb-wasm 工程里躺着没人用）。
- 但 `extension_config_wasm.cmake` 从上游 sync 过来的任何改动，**在我改之前就已经完全不生效了**——这是上游 duckdb-wasm 本身的现状（我拉了 upstream `main` 的 `lib/cmake/duckdb.cmake`、`lib/CMakeLists.txt`、`wasm_build_lib.sh` 核对，上游同样是死变量）。

不过你的顾虑是合理的：我现在是**硬编码**了 `DUCKDB_EXTENSION_CONFIGS`，如果将来上游把这条链路接通了（或者你自己接通），我的值会静默覆盖掉外部传入的值。这是真实的隐患。

## 2. 为什么 `duckdb_extension_load(sqlite_scanner ...)` 写在 `extension_config_wasm.cmake` 里编不出来

你没写错语法，是**这个文件根本没被 duckdb core 的 CMake 读到**（原因同上）。即使把它接通，原来那行还有两个会踩的坑：

1. **相对路径**：`DUCKDB_EXTENSION_CONFIGS=extension_config_wasm.cmake` 是相对路径，duckdb 的 `include()` 会相对 duckdb 源码目录解析，找不到文件。必须传绝对路径。
2. **`${CMAKE_CURRENT_SOURCE_DIR}` 语义翻转**：该文件被 `include()` 进 duckdb 的 `CMakeLists.txt` 后，`CMAKE_CURRENT_SOURCE_DIR` 是 **duckdb 的源码目录**，不是 duckdb-wasm 根目录，所以 `${CMAKE_CURRENT_SOURCE_DIR}/submodules/duckdb-sqlite` 指向了一个不存在的路径。要用 `CMAKE_CURRENT_LIST_DIR`（当前 .cmake 文件所在目录）。

另外扩展名建议用 `sqlite_scanner` 而不是 `sqlite`：产物库名由子模块自己的 `set(TARGET_NAME sqlite_scanner)` 决定，永远是 `libsqlite_scanner_extension.a`；用 `sqlite` 只会让 `DUCKDB_EXTENSION_SQLITE_LINKED` 之类的宏名和实际扩展名对不上。
