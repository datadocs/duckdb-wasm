# BUILDING DUCKDB-WASM ON GCP

View the video here to see the entire workflow of how these commands and actions are done. For a brand new machine, it takes about 25m to build everything. On an existing machine with the prerequisites installed it should take 10m or less.
​
## Starting VM
The VM is currently Boot Disk: Ubuntu 20.04, 40GB SSD | Machine type: e2-standard-8 (4 cores) | Network tags: http-server, https-server, duckdb-wasm. 
- Visit dukcdb-wasm VM url https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/duckdb-wasm2?project=datadocs-163219. 
- START the VM
- Open SSH to connect to VM
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
​
**Restart ssh-shell**. Do not skip this step.
​
## Clone and init duckdb-wasm repository
```sh
git clone https://github.com/datadocs/duckdb-wasm.git
cd duckdb-wasm
git submodule update --init
cd submodules/duckdb
git apply ../../duckdb.patch
cd ~
```
​
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
​
# clean previous build
make clean
​
# rebuild with latest update from `duckdb` repository
mkdir build
make build/bootstrap
DUCKDB_EXCEL=1 DUCKDB_JSON=1 DUCKDB_DATADOCS=1 make wasm 
```
​
- Building and running duckdb-shell
```sh
DUCKDB_EXCEL=1 DUCKDB_JSON=1 DUCKDB_DATADOCS=1 make
DUCKDB_EXCEL=1 DUCKDB_JSON=1 DUCKDB_DATADOCS=1 make app_start
```
​
## Running Duckdb-shell in browser
- Finding `external IP address` in `duckdb-wasm` VM instance (VM page https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/duckdb-wasm?project=datadocs-163219)
- Open browser and visit url: `http://<EXTERNAL_IP_ADDRESS>:9002/` (EG: http://35.247.34.76:9002/)
- 
- Running query with `ingest_file` function in duckdb-shell. Example query:
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

## Shut down the machine when you are finished as it's a large machine.
