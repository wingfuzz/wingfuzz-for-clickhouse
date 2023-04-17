#!/bin/bash

if [ -z "$3" ]; then
    echo "Usage: fuzz.sh CLICKHOUSE_BINARY SEEDS_DIR TEST_DIR"
    echo "   Run fuzzing test in docker with server CLICKHOUSE_BINARY"
    exit 1
fi

if [ -z "$WFUZZ_LICENSE" ]; then
    echo "WFUZZ_LICENSE is empty. You should set this environment to activate test tools"
    exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "$FUZZER_IMAGE" ]; then
    FUZZER_IMAGE=clickhouse-wingfuzz
fi

CLICKHOUSE_BINARY=`realpath $1`
SEEDS_DIR=`realpath $2`
TEST_DIR=`realpath $3`

docker run -it --rm \
    -v "$CLICKHOUSE_BINARY":/clickhouse:ro \
    -v "$SCRIPT_DIR/wfuzz.json:/workdir/wfuzz.json:ro" \
    -v "$SCRIPT_DIR/odbc.ini:/workdir/odbc.ini:ro" \
    -v "$SCRIPT_DIR/odbcinst.ini:/workdir/odbcinst.ini:ro" \
    -v "$SEEDS_DIR:/seeds:ro" \
    -v "$TEST_DIR":/test \
    -e WFUZZ_LICENSE="$WFUZZ_LICENSE" \
    $FUZZER_IMAGE \
    bash -c '/opt/wfuzz/bin/wfuzz fuzz /workdir --workdir=/test & tail -f --retry /test/1/griffin.log'
