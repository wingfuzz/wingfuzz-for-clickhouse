#!/bin/bash

source env.sh

if [ -z "$REPEAT" ]; then
    REPEAT=5
fi

if [ -f run-db.sh ] && [ -d project/anomaly/content ]; then
    COUNT=`ls project/anomaly/content | grep -c ''`
    echo "Start reproduce $COUNT cases with repeat $REPEAT times (set by REPEAT env)"
else
    echo "You should run this script in WINGFUZZ test file dir (like wfuzz-test-N/1/)"
    exit 1
fi

export SCRIPT_AFTER_FORCE_EXIT=""
export GRIFFIN_DONT_REDIRECT_OUTPUT=1
#LSAN is conflict with out ptrace watcher
export ASAN_OPTIONS=detect_leaks=0
export WFUZZ_LOG_KEEP_LINES=9999999

Reset=`tput sgr0`
Green=`tput setaf 2`
Red=`tput setaf 1`

function kill_server() {
    if [ -f ./data/server.pid ]; then
        PID=`cat ./data/server.pid`
        if [ -d /proc/$PID ]; then
            echo "Kill server pid $PID with SIGTERM"
            kill $PID
            for i in {1..5}; do
                sleep 1
                if [ ! -d /proc/$PID ]; then
                    break
                fi
            done
        fi
        if [ -d /proc/$PID ]; then
            echo "Server still alives, kill server pid $PID with SIGKILL"
            for i in {1..5}; do
                kill -9 $PID
                sleep 1
                if [ ! -d /proc/$PID ]; then
                    break
                fi
            done
        fi
    fi
    rm -f ./data/server.pid
}

trap "kill_server" EXIT

mkdir -p repro

echo "=========================================================="
for file in project/anomaly/content/*; do
    for repeat in {1..5}; do
        FN=`basename $file`
        rm -rf ./data
        echo "Start reproduce file $file $repeat times"
        timeout --foreground --kill-after=3s 300s $GRIFFIN_PATH/bin/reproduce_testcase test $file >repro/$FN.$repeat.repro.log 2>&1
        kill_server
        echo "Collecting server log files"
        touch ./server.log.2
        cat ./server.log.2 ./server.log.1 > repro/$FN.$repeat.server.log
        rm ./server.log.2 ./server.log.1

        FOUND_PROBLEM=

        grep AddressSanitizer repro/$FN.$repeat.server.log >/dev/null 2>&1
        if [ "$?" == "0" ]; then
            echo $Green"Found ASAN error in repro/$FN.$repeat.server.log"$Reset
            MSG=`grep AddressSanitizer repro/$FN.$repeat.server.log`
            echo $Green"MSG"$Reset
            touch repro/$FN.$repeat.asan_detected
            FOUND_PROBLEM=1
        fi

        grep 'force_exit_all' repro/$FN.$repeat.repro.log >/dev/null 2>&1
        if [ "$?" == "0" ]; then
            echo $Green"Found crash info in repro/$FN.$repeat.repro.log"$Reset
            touch repro/$FN.$repeat.crash_detected
            FOUND_PROBLEM=1
        fi

        if [ -z "$FOUND_PROBLEM" ]; then
            echo $Red"No reproducible problem found"$Reset
        fi
        echo "=========================================================="
    done
done
