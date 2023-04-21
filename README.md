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

1. Obtain a license

Before test you should obtain a license for WINGFUZZ.
For a trial you can contact us via email: contact@shuimuyulin.com.

The license is a string. You should set it with environment variable:
```
export WFUZZ_LICENSE=...
```

2. Unarchive seeds
```
tar xzvf seeds.tar.gz
```

3. Start fuzzing test with the following command:

```
./fuzz.sh PATH_TO_CLICKHOUSE_BINARY PATH_TO_SEEDS PATH_TO_TEST_DATA
```

Arguments: 

* `PATH_TO_CLICKHOUSE_BINARY`: Path to `clickhouse` binary, normally it is at `PATH_TO_BUILD/programs/clickhouse`.
* `PATH_TO_SEEDS`: Path to seeds. It contains several sql files.
* `PATH_TO_TEST_DATA`: A dir to store test files, like corpus, crashes, etc.

When you see something like:
```
Attempting dry run with 'id:000015,time:0,execs:0,orig:dump2.sql'...
    len = 1884, map size = 13936, exec speed = 7
```

It means the test is started normally and began to process initial seeds.


To find test results, goto dir `PATH_TO_TEST_DATA/1/project/anomaly`


## Analyzing fuzzing result

In the dir `PATH_TO_TEST_DATA/1/project/anomaly` there are 3 subdirs:

* `content`: Store the SQL statement which triggers crashes.
* `log`:     Last 2000 lines of server logs when the crash happened.
* `report`:  Last 2000 lines of logs of WINGFUZZ tools.

When a crash found, three files will be written to these dirs.
Their filename are same and naming like `id_000000_[timestamp]`.

The files in `content` and `log` are usually useful. 
Content file is used to reproduce the crash. 
You should start a server in a clean state and run the content file from any client.
If lucky you will see a crash happens.

Unfortunately, ClickHouse will crash randomly in many cases.
Results in an unreproducible content file. 
So log file is still important.
You can search crash patterns like `"AddressSanitizer"` in log file.
And analyze the stacktrace by hand.

## Reproduce the crashes

```
./repro.sh PATH_TO_CLICKHOUSE_BINARY PATH_TO_TEST_DATA PATH_TO_REPRO_DATA [REPEAT_TIMES]
```

Arguments: 

* `PATH_TO_CLICKHOUSE_BINARY`: Path to `clickhouse` binary, same as the fuzz script.
* `PATH_TO_TEST_DATA`: A dir to store test files, same as the fuzz script.
* `PATH_TO_REPRO_DATA`: A dir to store reproduce result.
* `REPEAT_TIMES`: Repeat times to run a single case.

Difference between fuzz and repro:

* In fuzzing mode the server will be started long period. 
Between cases we will run reset statement `DROP DATABASE ...; CREATE DATABASE ...`. But server is not restarted. Such statement may not fully reset the database.
   
* In reproduce mode the server will always started from an empty data dir. To make sure the state is fully clean. And server will be killed after each run. There is no reuse between cases to prevent internal state related problems.

In `PATH_TO_REPRO_DATA` there will be such files:

* `CONTENT_NAME.REPEAT.server.log`: The server log for `REPEAT`-th round of `CONTENT_NAME`.
* `CONTENT_NAME.REPEAT.wfuzz.log`: The WINGFUZZ tool log for `REPEAT`-th round of `CONTENT_NAME`.
* `CONTENT_NAME.REPEAT.asan_detected`: Only created when we find ASAN message (AddressSanitizer) in server log. Contains the ASAN message.
* `CONTENT_NAME.REPEAT.crash_detected`: Only created when we find some child process is killed by signal. Contains the PID ang signal number.

You can filter files with `asan_detected` or `crash_detected` to make the analyzing easier.
