#!/bin/bash -x

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/env.sh"

$SCRIPT_DIR/init.sh

TIME=`date +%Y%m%d%H%M%S`
echo "[wfuzz] start test"

# start database server and create necessary databases
echo "[wfuzz] starting server"
bash -x "$SCRIPT_DIR/run-server.sh" &

SERVER_PID=$(jobs -p)
echo "[wfuzz] server started at pid $SERVER_PID"
echo -n $SERVER_PID > $SCRIPT_DIR/server.pid
trap "kill $SERVER_PID" EXIT

# create directory for SDK to check
log_dir_parent=${TEST_DIR}/project/anomaly
mkdir -m 777 -p ${log_dir_parent}
log_content_dir=${log_dir_parent}/content
log_report_dir=${log_dir_parent}/report
mkdir -m 777 -p $log_content_dir
mkdir -m 777 -p $log_report_dir

ln -s $SCRIPT_DIR/input-set ${TEST_DIR}/project/in

# start fuzzing, -t specifies the timeout in ms
${GRIFFIN_PATH}/bin/afl-fuzz \
		-i ${TEST_DIR}/project/in \
		-o ${TEST_DIR}/project/afl_output_file \
		-t $(( ${ResetTimeoutLevel1} + ${ResetTimeoutLevel2} )) \
		-- ${GRIFFIN_PATH}/bin/autodriver_odbc_v5_aflpp test
