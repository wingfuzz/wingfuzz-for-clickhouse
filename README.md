# Test ClickHouse with WINGFUZZ

## 1. Update submodules

We use git submodules to store dependencies. 
You should update them before build the docker image.

```bash
# This submodule doesn't require recursive modules
git submodule update --init --progress aflpp
# But this submodule requires
git submodule update --init --progress --recursive clickhouse-odbc
```

## 2. Build docker image

```bash
docker build . -t clickhouse-wingfuzz
```

## 3. Build clickhouse

```bash
./build-clickhouse.sh PATH_TO_CLICKHOUSE PATH_TO_BUILD [PATH_TO_CACHE]
```

Arguments:

* `PATH_TO_CLICKHOUSE`: Path to clickhouse repo (https://github.com/ClickHouse/ClickHouse) with all submodules updated

* `PATH_TO_BUILD`: An empty dir to store built artifacts

* `PATH_TO_CACHE`: An empty dir to store caches (cargo and ccache). Can be omitted so there will be no cache.

Environment Variables:

* `NO_ASAN`: (Optional) By default, the script build clickhouse with Address Sanitizer. Run `export NO_ASAN=1` before build if you don't want it. Without asan, the server runs faster, but cannot detect some memory-related defects.
* `BUILDER_IMAGE`: (Optional) Name to the image built in [2. Build docker image](#2-build-docker-image). Defaults to `clickhouse-wingfuzz`

## 4. Start fuzzing test


