# RAPIDLY BUILDING DUCKDB-WASM

Updated at: 2023-11-07

The building manual in this section is only for Ubuntu and Mac OS.
Feel free to ask [me](https://github.com/hangxingliu) in the Slack if you encounter any
problems during the build

## Prerequisites

``` bash
# ===============
# Ubuntu:
sudo apt update && sudo apt install -y build-essential cmake git ccache;
# Install Node.js manually from https://nodejs.org/
# ===============
# Mac OS:
brew install make cmake git ccache node
# ===============
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

## First Build

``` bash
git clone https://github.com/datadocs/duckdb-wasm.git
cd duckdb-wasm
git submodule update --init --depth=1
yarn install # OR npm install
source /path/to/your/emsdk/emsdk_env.sh # REMEMBER to replace the path here
./scripts/datadocs_fast_rebuild.sh all
# NOTICE: The first complete build can take a long time, the reference times are here:
# Base hardware information: MacBook Pro 2019 (2.6GHz 6-Core Intel i7)
#
#   ~7m  for a brand new environment
#   ~6m  for a new environment but built emscripten before
#   ~24m for a brand new environment with the option `--release`
#
# NOTICE: please ensure your network is stable and can access the following domains:
# - *.github.com
# - *.githubusercontent.com
# - *.yarnpkg.com
```

## Subsequent Builds

``` bash
./scripts/datadocs_fast_rebuild.sh
```

## Build for Release

``` bash
./scripts/datadocs_fast_rebuild.sh --release all
# You can take a break after executing this command, because it can take a long time
```

## Build and Run DuckDB Web Shell

``` bash
# please make sure you have run `yarn install` before
yarn workspace @duckdb/duckdb-wasm-shell build:debug && yarn workspace @duckdb/duckdb-wasm-app start
```

## More Tips

You can mount a RAMDISK at `/path/to/your/duckdb-wasm/build` to improve the building process.
The minimum size of this RAMDISK is **4GB**, the recommanded size of it is **8GB** (Becuase you may need to build for release and dev)


# BUILDING DUCKDB-WASM ON GCP

View the video here to see the entire workflow of how these commands and steps are done using GCP: https://youtu.be/yBhYkIRuoWQ.

For a brand new machine, it takes about 25m to build everything. On an existing machine with the prerequisites installed it should take 10m or less.
​
## Starting VM
You may use a free GCP or AWS account to following the below installation. The below has been tested using GCP (if you are a current developer with GCP access use [this link](https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/duckdb-wasm2?project=datadocs-163219) to view the instance).

The VM currently has Boot Disk: Ubuntu 20.04, 40GB SSD.

Make sure Port 9002 is open. 
​
## Prerequisites (Linux):
Install package following commands:
```sh
# update apt
sudo apt-get update
#install make
sudo apt install make
# install git-lfs
sudo apt-get install git-lfs
# install cmake
sudo apt install cmake
# install nodejs (specific version)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
source ~/.bashrc
nvm install v18.0.0
# install npm
sudo apt-get install npm
# install yarn
sudo npm install --global yarn
# install ccache
sudo apt-get install -y ccache
# install emscripten
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
cd ..
# install rust
curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh
```

**Restart ssh-shell**. Do not skip this step.
​
## Clone and init duckdb-wasm repository
```sh
git clone https://github.com/datadocs/duckdb-wasm.git
cd duckdb-wasm
git submodule update --init
cd ~
```

Currently we have two branches:
- master: building all packages in duckdb-wasm (mvp, eh, coi)
- test_build_mvp (testing only): building one package mvp (ignore eh and coi) -- reduces build time by an hour! This will be the default when you build.
​
## Building duckdb-wasm (If on an existing machine with pre-requisites installed, start here)
Building step:
- (`Options` for change submodule `duckdb` only) Update submodule `duckdb`, clean previvous `build` folder and rebuild with latest update from `duckdb` repository
```sh
# go into duckdb-dir and initialize emscripten environment 
source ./emsdk/emsdk_env.sh
cd duckdb-wasm

# use the Test branch if we want to speed up build times
git checkout test_build_mvp
git pull origin test_build_mvp

# update submodule `duckdb`
cd submodules/duckdb
git checkout .
git pull origin ingest
git apply ../../duckdb.patch
cd ../../
git apply fix.patch
​
# clean previous build
make clean
​
# rebuild with latest update from `duckdb` repository
mkdir build
make build/bootstrap
DUCKDB_EXCEL=1 DUCKDB_JSON=1 DUCKDB_DATADOCS=1 make wasm 
```

- Building and running duckdb-shell
```sh
DUCKDB_EXCEL=1 DUCKDB_JSON=1 DUCKDB_DATADOCS=1 make
DUCKDB_EXCEL=1 DUCKDB_JSON=1 DUCKDB_DATADOCS=1 make app_start
```

## Running Duckdb-shell in browser
- Find the external IP address for the instance. Copy the IP to your clipboard.
- Open browser and visit url: `http://<EXTERNAL_IP_ADDRESS>:9002/` (EG: http://35.247.34.76:9002/)
- Run the query with `ingest_file` function in duckdb-shell. Example query:
```query
# remote
SELECT * from ingest_file("https://support.staffbase.com/hc/en-us/article_attachments/360009197031/username.csv");

# local
.files ADD
[add a local file -- in this example I'm using the file Sales1M.csv]
SELECT * FROM ingest_file('Sales1M.csv')
```
Currently it shows the following error if you open the JS console in Developer Tools:
```
missing function: ucsdet_open_64
duckdb-browser-eh.worker.63dcc272ecdd5657c10a.js:1 Aborted(-1)
duckdb-browser-eh.worker.63dcc272ecdd5657c10a.js:1 RuntimeError: unreachable
    at 04ce4786:0xf81293
    at Tc (duckdb-browser-eh.worker.63dcc272ecdd5657c10a.js:1:29557)
    at G (duckdb-browser-eh.worker.63dcc272ecdd5657c10a.js:1:4719)
    at Hf (duckdb-browser-eh.worker.63dcc272ecdd5657c10a.js:1:24116)
    at 04ce4786:0xcb5145
    at 04ce4786:0xcac761
    at 04ce4786:0xca72e5
    at 04ce4786:0x66b469
    at 04ce4786:0x66ab48
    at 04ce4786:0xc05e5
```
