#!/bin/bash

# Reset=`tput sgr0`
# Green=`tput setaf 2`
# Red=`tput setaf 1`

TIMEOUT=60s

if [ -z "$WFUZZ_REPRO_IN_DOCKER" ]; then
    #outside docker
    
    if [ -z "$3" ]; then
        echo "Usage: repro.sh CLICKHOUSE_BINARY TEST_DIR REPRO_DIR [REPEAT_TIMES=5]"
        echo "   Reproduct all cases found by previous fuzzing test"
        exit 1
    fi
    
    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

    if [ -z "$FUZZER_IMAGE" ]; then
        FUZZER_IMAGE=clickhouse-wingfuzz
    fi

    CLICKHOUSE_BINARY=`realpath $1`
    TEST_DIR=`realpath $2`
    REPRO_DIR=`realpath $3`
    REPEAT_TIMES=$4

    if [ -z "$REPEAT_TIMES" ]; then
        REPEAT_TIMES=5
    fi

    mkdir -p $REPRO_DIR

    CONTENT_DIR=$TEST_DIR/1/project/anomaly/content

    for FILE in `ls $CONTENT_DIR`; do
        for REPEAT in `seq $REPEAT_TIMES`; do
            echo "Repro $FILE ... $REPEAT"
            docker run -it --rm \
                -v "$CLICKHOUSE_BINARY":/clickhouse:ro \
                -v "$SCRIPT_DIR/repro.sh:/repro.sh:ro" \
                -v "$SCRIPT_DIR/wfuzz.json:/workdir/wfuzz.json:ro" \
                -v "$SCRIPT_DIR/odbc.ini:/workdir/odbc.ini:ro" \
                -v "$SCRIPT_DIR/odbcinst.ini:/workdir/odbcinst.ini:ro" \
                -v "$CONTENT_DIR/$FILE:/$FILE:ro" \
                -v "$TEST_DIR":/test \
                -v "$REPRO_DIR":/repro \
                -e WFUZZ_REPRO_IN_DOCKER=1 \
                -e WFUZZ_REPRO_DEBUG_START_SHELL=$WFUZZ_REPRO_DEBUG_START_SHELL \
                -e FILE="$FILE" \
                -e TARGET="/$FILE" \
                -e REPEAT="$REPEAT" \
                $FUZZER_IMAGE \
                /repro.sh
            if [ ! "$?" == "0" ]; then
                exit 1
            fi
            if [ ! -z "$WFUZZ_REPRO_DEBUG_START_SHELL" ]; then
                exit 0
            fi
        done
    done
else
    #inside docker
    source /test/1/env.sh

    export SCRIPT_AFTER_FORCE_EXIT=""
    export GRIFFIN_DONT_REDIRECT_OUTPUT=1
    export ASAN_OPTIONS=detect_leaks=0
    export WFUZZ_LOG_KEEP_LINES=9999999

    if [ ! -z "$WFUZZ_REPRO_DEBUG_START_SHELL" ]; then
        export PATH="$PATH:/opt/wfuzz/tools/Linux-x86_64/griffin/1.0.0/bin"
        echo "Start reproduce with command:"
        echo "    reproduce_testcase test $TARGET"
        bash
        exit 0
    fi

    echo "Start server and run testcase $FILE"

    timeout --foreground --kill-after=3s $TIMEOUT \
        /opt/wfuzz/tools/Linux-x86_64/griffin/1.0.0/bin/reproduce_testcase test $TARGET > /repro/$FILE.$REPEAT.wfuzz.log 2>&1

    WAIT_BEFORE_CRASH=10

    echo "Wait $WAIT_BEFORE_CRASH seconds to see if server is crashing"

    for WAIT_REPEAT in `seq $WAIT_BEFORE_CRASH`; do
        sleep 1
        echo "select 12345 + 1" | isql test | grep 12346 >/dev/null 2>&1
        if [ ! "$?" == "0" ]; then
            break
        fi
    done

    echo "Collecting server log files"
    touch /test/1/server.log.2
    cat /test/1/server.log.2 /test/1/server.log.1 > /repro/$FILE.$REPEAT.server.log
    rm /test/1/server.log.2 /test/1/server.log.1

    FOUND_PROBLEM=

    grep AddressSanitizer /repro/$FILE.$REPEAT.server.log >/dev/null 2>&1
    if [ "$?" == "0" ]; then
        echo $Green"Found ASAN error in /repro/$FILE.$REPEAT.server.log"$Reset
        grep AddressSanitizer /repro/$FILE.$REPEAT.server.log > /repro/$FILE.$REPEAT.asan_detected
        FOUND_PROBLEM=1
    fi

    grep 'force_exit_all' /repro/$FILE.$REPEAT.wfuzz.log >/dev/null 2>&1
    if [ "$?" == "0" ]; then
        echo $Green"Found crash info in /repro/$FILE.$REPEAT.wfuzz.log"$Reset
        grep "stoped signal number" /repro/$FILE.$REPEAT.wfuzz.log > /repro/$FILE.$REPEAT.crash_detected
        FOUND_PROBLEM=1
    fi

    if [ -z "$FOUND_PROBLEM" ]; then
        echo $Red"No reproducible problem found"$Reset
    fi

    exit 0
fi
