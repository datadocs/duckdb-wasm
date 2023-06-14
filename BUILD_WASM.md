# Installation

## Prerequisites (Mac):

```sh
brew install emscripten
brew install rust
brew install ccache
brew install git-lfs
```

### Modify submodule duckdb

```sh
cd submodules/duckdb
git apply ../../duckdb.patch
cd ../..
```

### Building wasm files

```sh
mkdir build
make build/bootstrap
DUCKDB_EXCEL=1 DUCKDB_JSON=1 DUCKDB_DATADOCS=1 make wasm
make js_release
```

### Testing wasm files

Location of wasm file

```
packages/duckdb-wasm/dist
```

Copping following files to datadocs project (destination folder: `/packages/datadocs/src/lib/wasm/duckdb`)

-   duckdb-browser-coi.worker.js
-   duckdb-browser-eh.worker.js
-   duckdb-browser-mvp.worker.js
-   duckdb-coi.wasm
-   duckdb-eh.wasm
-   duckdb-mvp.wasm

### Restart datadocs application
