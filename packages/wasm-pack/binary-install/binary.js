const { existsSync, mkdirSync, copyFileSync } = require('fs');
const { join } = require('path');
const { spawnSync } = require('child_process');
const { platform } = require('os');

const axios = require('axios');
const tar = require('tar');
const rimraf = require('rimraf');
const https = require('https');

const error = msg => {
    console.error(msg);
    process.exit(1);
};

class Binary {
    constructor(name, url, version, config) {
        let errors = [];
        if (typeof url !== 'string') {
            errors.push('url must be a string');
        } else {
            try {
                new URL(url);
            } catch (e) {
                errors.push(e);
            }
        }
        if (name && typeof name !== 'string') {
            errors.push('name must be a string');
        }

        if (version && typeof version !== 'string') {
            errors.push('version must be a string');
        }

        if (!name) {
            errors.push('You must specify the name of your binary');
        }

        if (!version) {
            errors.push('You must specify the version of your binary');
        }

        if (config && config.installDirectory && typeof config.installDirectory !== 'string') {
            errors.push('config.installDirectory must be a string');
        }

        if (errors.length > 0) {
            let errorMsg = 'One or more of the parameters you passed to the Binary constructor are invalid:\n';
            errors.forEach(error => {
                errorMsg += error;
            });
            errorMsg +=
                '\n\nCorrect usage: new Binary("my-binary", "https://example.com/binary/download.tar.gz", "v1.0.0")';
            error(errorMsg);
        }
        this.url = url;
        this.name = name;
        this.version = version;
        this.installDirectory = config?.installDirectory || join(__dirname, '..', 'node_modules', '.bin');

        if (!existsSync(this.installDirectory)) {
            mkdirSync(this.installDirectory, { recursive: true });
        }

        this.binaryPath = join(this.installDirectory, `${this.name}`); //-${this.version}`);
        this.predownloadedBinPath = join(__dirname, '..', `${this.name}`); //-${this.version}`);
    }

    exists() {
        return existsSync(this.binaryPath);
    }

    install(fetchOptions, suppressLogs = false) {
        if (!suppressLogs) {
            console.error(`Expected target binary file: ${this.binaryPath}`);
        }

        if (existsSync(this.predownloadedBinPath)) {
            console.error(`Installing from '${this.predownloadedBinPath}'`);
            copyFileSync(this.predownloadedBinPath, this.binaryPath);
            if (platform() !== 'win32') {
                const result = spawnSync('chmod', ['+x', this.binaryPath], { stdio: 'inherit' });
                if (result.error) console.error(result.error.stack);
            }
            return;
        }

        if (this.exists()) {
            if (!suppressLogs) {
                console.error(`${this.name} is already installed, skipping installation.`);
            }
            return Promise.resolve();
        }

        if (existsSync(this.installDirectory)) {
            rimraf.sync(this.installDirectory);
        }

        mkdirSync(this.installDirectory, { recursive: true });

        if (!suppressLogs) {
            console.error(`Downloading release from ${this.url} to '${this.installDirectory}'`);
        }

        //#region respect system proxy env vars
        // 1. we assume the binary download URL is HTTPS
        // 2. ignore `no_proxy` env var because this snippet is too short to parse it
        let httpsAgent = new https.Agent();
        {
            let proxyURL = process.env.https_proxy || process.env.HTTPS_PROXY || '';
            if (!proxyURL.startsWith('http')) {
                proxyURL = process.env.all_proxy || process.env.ALL_PROXY || '';
                if (!proxyURL.startsWith('http')) {
                    proxyURL = process.env.http_proxy || process.env.HTTP_PROXY || '';
                    if (!proxyURL.startsWith('http')) proxyURL = '';
                }
            }
            try {
                if (proxyURL) {
                    const Agent = require('https-proxy-agent').HttpsProxyAgent;
                    httpsAgent = new Agent(new URL(proxyURL));
                    console.error(`Use proxy '${proxyURL}'`);
                }
            } catch (error) {
                console.error(error);
            }
        }
        //#endregion

        return axios({
            ...fetchOptions,
            url: this.url,
            responseType: 'stream',
            // The built-in proxy handler from axios has incorrect implementation that
            // could cause errors
            proxy: false,
            httpsAgent,
        })
            .then(res => {
                return new Promise((resolve, reject) => {
                    const sink = res.data.pipe(tar.x({ strip: 1, C: this.installDirectory }));
                    sink.on('finish', () => resolve());
                    sink.on('error', err => reject(err));
                });
            })
            .then(() => {
                if (!suppressLogs) {
                    console.error(`${this.name} has been installed!`);
                }
            })
            .catch(e => {
                error(`Error fetching release: ${e.message}`);
            });
    }

    run(fetchOptions) {
        const promise = !this.exists() ? this.install(fetchOptions, true) : Promise.resolve();

        promise
            .then(() => {
                const [, , ...args] = process.argv;

                const options = { cwd: process.cwd(), stdio: 'inherit' };

                const result = spawnSync(this.binaryPath, args, options);

                if (result.error) {
                    error(result.error);
                }

                process.exit(result.status);
            })
            .catch(e => {
                error(e.message);
                process.exit(1);
            });
    }
}

module.exports.Binary = Binary;
