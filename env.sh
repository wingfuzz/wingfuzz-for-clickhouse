
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export DATABASE=$SCRIPT_DIR/build/programs/clickhouse-server
export PORT=43361
export TEST_DIR="$SCRIPT_DIR/test"

export ODBCINI="$SCRIPT_DIR/odbc.ini"
export ODBCINSTINI='odbcinst.ini'
export ODBCSEARCH='ODBC_USER_DSN'
export ODBCSYSINI="$SCRIPT_DIR"
export SCRIPT_AFTER_FORCE_EXIT="$SCRIPT_DIR/script_after_force_exit.sh"

export DATADIR="$TEST_DIR/data"
export AFL_MAP_SIZE='4000000'
export AFL_INST_RATIO=30
export AFL_CRASH_EXITCODE='88'
export AFL_CUSTOM_MUTATOR_LIBRARY='/root/.wfuzz/tools/Linux-x86_64/griffin/1.0.0-debug/lib/libmerge_odbc_ver_dynamic.so'
export AFL_CUSTOM_MUTATOR_ONLY='1'
export AFL_DISABLE_TRIM='1'
export AFL_FAST_CAL='1'
export AFL_IGNORE_PROBLEMS='1'
export AFL_NO_AFFINITY='1'
export AFL_SHUFFLE_QUEUE='1'
export MetaQuery='postgres'
export BlackList=''
export GRIFFIN_PATH='/root/.wfuzz/tools/Linux-x86_64/griffin/1.0.0-debug/'
export INSTANCE='1'
export LEGO_MAP_SIZE_DEFAULT_VALUE=$AFL_MAP_SIZE
export PortToCheck=$PORT
export ResetStmtsCheck=''
export ResetTimeoutLevel1='50000'
export ResetTimeoutLevel2='50000'
export SQLSIM_DSN_NAME='test2'
export SQLSIM_TIMEOUT_MS='10000'

